#
# Integers
#

[integer/-s]

Signature Integers. An integer is a notion.

Let a,b,c,d,i,j,k,l,m,n stand for integers.

Signature IntZero.  0 is an integer.
Signature IntOne.   1 is an integer.
Signature IntNeg.   -a is an integer.
Signature IntPlus.  a + b is an integer.
Signature IntMult.  a * b is an integer.

Let a - b stand for a + (-b).

Axiom AddAsso.      a + (b + c) = (a + b) + c.
Axiom AddComm.      a + b = b + a.
Axiom AddZero.      a + 0 = a = 0 + a.
Axiom AddNeg.       a - a = 0 = -a + a.

Axiom MulAsso.      a * (b * c) = (a * b) * c.
Axiom MulComm.      a * b = b * a.
Axiom MulOne.       a * 1 = a = 1 * a.

Axiom Distrib.      a * (b + c) = (a*b) + (a*c) and
                    (a + b) * c = (a*c) + (b*c).

Lemma MulZero.      a * 0 = 0 = 0 * a.
Lemma MulMinOne.    -1 * a = -a = a * -1.

Axiom ZeroDiv.      a * b = 0 => a = 0 \/ b = 0.

Let a is nonzero stand for a != 0.
Let p,q stand for nonzero integers.

[divisor/-s] [divide/-s]

Definition Divisor. A divisor of b is a nonzero integer a
                    such that for some n (a * n = b).

Let a divides b stand for a is a divisor of b.
Let a | b stand for a is a divisor of b.

Definition EquMod.  a = b (mod q) iff q | a-b.

Lemma EquModRef.    a = a (mod q).

Lemma EquModSym.    a = b (mod q) => b = a (mod q).
Proof.
    Assume that a = b (mod q).
    Take n such that q * n = a - b.
    We have q * -n = b - a.
qed.

Lemma EquModTrn.    a = b (mod q) /\ b = c (mod q) => a = c (mod q).
Proof.
    Assume that a = b (mod q) /\ b = c (mod q).
    Take n such that q * n = a - b.
    Take m such that q * m = b - c.
    We have q * (n + m) = a - c.
qed.

Lemma EquModMul. a = b (mod p * q) => a = b (mod p) /\ a = b (mod q).
Proof.
    Assume that a = b (mod p * q).
    Take m such that (p * q) * m = a - b.
    We have p * (q * m) = a - b = q * (p * m).
qed.

Signature Prime.    p is prime is an atom.

Let a prime stand for a prime nonzero integer.

Axiom PrimeDivisor. n has a prime divisor iff n != 1 /\ n != -1.


#
# Generic sets
#

[set/-s] [element/-s] [belong/-s] [subset/-s]

Signature Sets.     A set is a notion.

Let S,T stand for sets.

Signature Elements. An element of S is a notion.

Let x belongs to S stand for x is an element of S.
Let x << S stand for x is an element of S.

Definition Subset.  A subset of S is a set T such that
                        every element of T belongs to S.

Let S [= T stand for S is a subset of T.

Signature FinSet.   S is finite is an atom.

Let x is infinite stand for x is not finite.


#
# Sets of integers
#

Let INT denote the set of integers.
Let A,B,C,D stand for subsets of INT.

Definition Union.
    A \-/ B = { integer x | x << A \/ x << B }.

Definition Intersection.
    A /-\ B = { integer x | x << A /\ x << B }.

Definition UnionSet.
    Let S be a set such that every element of S is a subset of INT.
    \-/ S = { integer x | x belongs to some element of S }.

Definition Complement.
    ~ A = { integer x | x does not belong to A }.


#
# Introducing topology
#

Definition ArSeq.   ArSeq(a,q) = { b | b = a (mod q) }.

Definition Open.    A is open iff for any a << A
                        there exists q such that ArSeq(a,q) [= A.

Definition Closed.  A is closed iff ~A is open.

Lemma UnionOpen.    Let S be a set such that
                        all elements of S are open subsets of INT.
                    \-/ S is open.

Lemma InterOpen.    Let A,B be open subsets of INT.
                    A /-\ B is open (by ZeroDiv,EquModMul).

Lemma UnionClosed.  Let A,B be closed subsets of INT.
                    A \-/ B is closed.
Proof.
    We have ~A,~B [= INT and ~(A \-/ B) = ~A /-\ ~B.
qed.

Axiom UnionSClosed. Let S be a finite set such that
                        all elements of S are closed subsets of INT.
                    \-/ S is closed.

Lemma ArSeqClosed.  ArSeq(a,q) is a closed subset of INT.
Proof.
    If b << ~ArSeq(a,q) and c = b (mod q) then c << ~ArSeq(a,q).
qed.

Theorem Fuerstenberg.   Let S = { ArSeq(0,r) | r is a prime }.
                        S is infinite.
Proof.
    We have ~ \-/ S = {1, -1}.
    Indeed n belongs to \-/ S iff n has a prime divisor.

    Assume that S is finite.
    Then \-/ S is closed and ~ \-/ S is open.

    Take p such that ArSeq(1,p) [= ~ \-/ S.
    ArSeq(1,p) has an element that does not belong to {1, -1}.
    proof.
        1 + p and 1 - p belong to ArSeq(1,p).
        1 + p !=  1 /\ 1 - p !=  1.
        1 + p != -1 \/ 1 - p != -1.
    end.
    We have a contradiction.
qed.
