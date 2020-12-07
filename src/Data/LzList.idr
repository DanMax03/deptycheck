module Data.LzList

import Data.Fin
import Data.List

import Decidable.Equality

%default total

data LzVect : Nat -> Type -> Type

||| List with lazy contents and statically known size.
export
record LzList a where
  constructor MkLzList
  length   : Nat
  contents : Lazy (LzVect length a)

%name LzList xs, ys, zs

export
data LzVect : Nat -> Type -> Type where
  Eager  : (xs : List a) -> LzVect (length xs) a
  Cons   : a -> (xs : LzList a) -> LzVect (S xs.length) a
  Concat : (ls : LzList a) -> (rs : LzList a) -> LzVect (ls.length + rs.length) a
  Map    : (a -> b) -> (xs : LzList a) -> LzVect xs.length b
  Cart   : (os : LzList a) -> (is : LzList b) -> LzVect (os.length * is.length) (a, b)

%name LzVect lvxs, lvys, lvzs

--- Common functions ---

export
Nil : LzList a
Nil = MkLzList 0 $ Eager []

export
(::) : a -> LzList a -> LzList a
x :: xs = MkLzList _ $ Cons x xs

export
(++) : LzList a -> LzList a -> LzList a
xs ++ ys = MkLzList _ $ Concat xs ys

splitSumFin : {a, b : Nat} -> Fin (a + b) -> Either (Fin a) (Fin b)

splitProdFin : {a, b : Nat} -> Fin (a * b) -> (Fin a, Fin b)

export
index : (lz : LzList a) -> Fin lz.length -> a
index lz i = ind (force lz.contents) i where
  ind : forall a. LzVect n a -> Fin n -> a
  ind (Eager xs)     i      = index' xs i
  ind (Cons x _)     FZ     = x
  ind (Cons _ xs)    (FS i) = index xs i
  ind (Concat ls rs) i      = assert_total $ either (index ls) (index rs) $ splitSumFin i
  ind (Map f xs)     i      = f $ assert_total $ index xs i
  ind (Cart os is)   i      = let (oi, ii) = splitProdFin i in assert_total $ (index os oi, index is ii)

-------------------------------------------------
--- Funny implementations of funny interfaces ---
-------------------------------------------------

--- Functor-related ---

Functor LzList where
  map f xso = ?map_o_rhs

mapMaybe : (f : a -> Maybe b) -> LzList a -> LzList a

zipWith : (f : a -> b -> c) -> LzList a -> LzList b -> LzList c

Applicative LzList where
  pure x = MkLzList 1 $ Eager [x]
  xso <*> yso = ?ap_n_rhs

--- Folds ---

Foldable LzList where
  foldr = ?foldr_rhs

Traversable LzList where
  traverse = ?traverse_rhs

--- Show ---

Show a => Show (LzList a) where
  show = show . toList
