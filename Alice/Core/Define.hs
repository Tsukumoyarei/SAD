module Alice.Core.Define (fillDef) where

import Control.Monad
import Data.Maybe

import Alice.Data.Formula
import Alice.Data.Kit
import Alice.Data.Instr
import Alice.Data.Text
import Alice.Core.Base
import Alice.Core.Local
import Alice.Core.Reason

fillDef :: Context -> [Context] -> Context -> RM Formula
fillDef ths cnt cx  = fill True False [] (Just True) 0 $ cnForm cx
  where
    fill pr nw fc sg n (Ann DHD f)
      = liftM (Ann DHD) $ fill pr True fc sg n f
    fill _ _ fc _ _ t | isThesis t
      = return $ cnForm ths
    fill pr _ fc _ _ v | isVar v
      = do  uin <- askRSIB IBinfo True
            let nct = cnRaise cnt cx fc
            return $ sinfo uin pr nct v
    fill pr nw fc sg n (Trm t ts is)
      = do  uin <- askRSIB IBinfo True
            let nct = cnRaise cnt cx fc
            nts <- mapM (fill False   nw fc sg n) ts
            nis <- mapM (fill True False fc sg n) is
            ntr <- setDef nw nct cx $ Trm t nts nis
            return $ sinfo uin pr nct $ specDef ntr
    fill pr nw fc sg n f = roundFM (fill pr nw) fc sg n f

    sinfo True pr cnt = setInfo pr cnt
    sinfo _ _ _       = id

setDef :: Bool -> [Context] -> Context -> Formula -> RM Formula
setDef nw cnt cx trm@(Trm t _ _)
    =  (guard (elem ':' t) >> return trm)
    <> (guardNotIB IBdefn True >> return trm)
    <> (msum $ map (testDef False cnt cx trm) dfs)
    <> (guard (t == "=" || elem '#' t) >> return trm)
    <> (msum $ map (testDef True  cnt cx trm) dfs)
    <> (guard nw >> return str)
    <> (out >> mzero)
  where
    dfs = mapMaybe (findDef trm) cnt
    str = trm { trName = t ++ ':' : show (length dfs) }
    out = rlog (cnHead cx) $ "unrecognized: " ++ showsPrec 2 trm ""


-- Find relevant definitions and test them

type DefTrio = (Context, Formula, Formula)

findDef :: (MonadPlus m) => Formula -> Context -> m DefTrio
findDef trm cx  = dive Top 0 $ cnForm cx
  where
    dive gs _ (Iff (Ann DHD (Trm "=" [Var v _, t] _)) f) | isTrm t
                                  = fine gs t $ Ann DEQ $ subst t v f
    dive gs _ (Imp (Ann DHD (Trm "=" [Var v _, t] _)) f) | isTrm t
                                  = fine gs t $ Ann DIM $ subst t v f
    dive gs _ (Iff (Ann DHD t) f) = fine gs t $ Ann DEQ f
    dive gs _ (Imp (Ann DHD t) f) = fine gs t $ Ann DIM f

    dive gs n (All _ f) = dive gs (succ n) $ inst ('?':show n) f
    dive gs n (Imp g f) = dive (bool $ And gs g) n f
    dive _ _ _          = mzero

    fine gs tr@(Trm t _ _) fr =
      do  ngs <- match otr trm `ap` return gs
          nfr <- match otr wtr `ap` return fr
          return (cx, ngs, trm { trName = t, trInfo = [nfr] })
      where otr = tr { trName = takeWhile (/= ':') t }

    wtr = wipeInfo trm

testDef :: Bool -> [Context] -> Context -> Formula -> DefTrio -> RM Formula
testDef hard cnt cx trm (dc, gs, nt)
    = setup >> (guards <> (cleanup >> mzero)) >> cleanup >> return nt
  where
    guards  | hard  = do  whdchk $ header
                          reason cnt $ setForm cx gs
            | True  = do  guard $ rapid gs
                          whdchk $ "trivial " ++ header

    setup   | hard  = do  askRSII IIchtl 1 >>= addRSIn . InInt IItlim
                          askRSII IIchdl 3 >>= addRSIn . InInt IIdpth
            | True  = return ()

    cleanup | hard  = do  drpRSIn $ IdInt IItlim
                          drpRSIn $ IdInt IIdpth
            | True  = return ()

    header  = "check: " ++ showsPrec 2 trm " vs " ++ cnName dc
    whdchk  = whenIB IBdchk False . rlog0


-- Infer ad hoc definitions

specDef :: Formula -> Formula
specDef trm@(Trm "=" [l, r] _) | not (null nds)  = ntr
  where
    ntr = Trm "=" [l, r { trInfo = map (Ann DIM) $ trInfoI r }] (ods ++ nds)
    ods = map (Ann DIM) (trInfoI trm) ++ map (Ann DEQ) (trInfoE trm)
    nds = map (Ann DSD . replace (wipeInfo l) r) $ trInfoD r

specDef trm | isTrm trm = otr { trInfo = nds }
  where
    (nds, otr) = pas ods trm
    ods = map (Ann DIM) (trInfoI trm) ++ map (Ann DEQ) (trInfoE trm)

    pas ds t | isTrm t
      = let (nd, as) = foldr arg (ds, []) $ trArgs t
        in  (nd, t { trArgs = as })
    pas ds t = (ds, t)

    arg a (ds, as)
      = let (ad, na) = pas ds a
            (nd, is) = foldr tst (ad, []) $ trInfo a
        in  (nd, na { trInfo = is } : as)

    tst a@(Ann DEQ d) (nd, ds)
      = case specDig trm d
        of  Just f  ->  (Ann DSD f : nd, ds)
            _       ->  (nd, a : ds)

    tst a@(Ann DSD d) (nd, ds)
      = case specDig trm d
        of  Just f  ->  (Ann DSD f : nd, ds)
            _       ->  (nd, a : ds)

    tst a@(Ann DIM (Not d)) (nd, ds)
      = let (ni, _) = foldr tst (nd, []) $ concatMap trInfo $ trInfoO d
        in  (ni, a : ds)

    tst a@(Ann DIM d) (nd, ds)
      = let (ni, _) = foldr tst (nd, []) $ trInfo d
        in  (ni, a : ds)

    tst a (nd, ds)  = (nd, a : ds)

specDef f = f

specDig :: (MonadPlus m) => Formula -> Formula -> m Formula
specDig trm = dive Top 0
  where
    dive gs _ (Iff (Trm "=" [l@(Var v@('?':_) _), t] _) f)
      | isTrm t && not (occurs l t) = fine gs t $ subst t v f
    dive gs _ (Iff t f) | isTrm t   = fine gs t f
    dive gs n (All _ f) = dive gs (succ n) $ inst ('?':show n) f
    dive gs n (Imp g f) = dive (bool $ And gs g) n f
    dive gs n (And f g) = dive gs n f `mplus` dive gs n g
    dive _ _ _          = mzero

    fine gs tr@(Trm t _ _) fr =
      do  nfr <- match tr wtr `ap` return fr; guard $ green nfr
          ngs <- match tr trm `ap` return gs; guard $ green ngs
          guard $ rapid ngs; return nfr

    wtr = wipeInfo trm

