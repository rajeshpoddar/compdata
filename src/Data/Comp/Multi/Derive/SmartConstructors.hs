{-# LANGUAGE TemplateHaskell #-}
--------------------------------------------------------------------------------
-- |
-- Module      :  Data.Comp.Multi.Derive.SmartConstructors
-- Copyright   :  (c) 2011 Patrick Bahr
-- License     :  BSD3
-- Maintainer  :  Patrick Bahr <paba@diku.dk>
-- Stability   :  experimental
-- Portability :  non-portable (GHC Extensions)
--
-- Automatically derive smart constructors for mutually recursive types.
--
--------------------------------------------------------------------------------

module Data.Comp.Multi.Derive.SmartConstructors
    (
     smartConstructors
    ) where

import Control.Arrow ((&&&))
import Control.Monad
import Data.Comp.Derive.Utils
import Data.Comp.Multi.Sum
import Data.Comp.Multi.Term
import Language.Haskell.TH hiding (Cxt)

{-| Derive smart constructors for a type constructor of any higher-order kind
 taking at least two arguments. The smart constructors are similar to the
 ordinary constructors, but an 'inject' is automatically inserted. -}
smartConstructors :: Name -> Q [Dec]
smartConstructors fname = do
    Just (DataInfo _cxt tname targs constrs _deriving) <- abstractNewtypeQ $ reify fname
    let iVar = tyVarBndrName $ last targs
    let cons = map (abstractConType &&& iTp iVar) constrs
    liftM concat $ mapM (genSmartConstr (map tyVarBndrName targs) tname) cons
        where iTp iVar (ForallC _ cxt _) =
                  -- Check if the GADT phantom type is constrained
                  case [y | Just (x, y) <- map isEqualP cxt, x == VarT iVar] of
                    [] -> Nothing
                    tp:_ -> Just tp
              iTp _ _ = Nothing
              genSmartConstr targs tname ((name, args), miTp) = do
                let bname = nameBase name
                genSmartConstr' targs tname (mkName $ 'i' : bname) name args miTp
              genSmartConstr' targs tname sname name args miTp = do
                varNs <- newNames args "x"
                let pats = map varP varNs
                    vars = map varE varNs
                    val = foldl appE (conE name) vars
                    sig = genSig targs tname sname args miTp
                    function = [funD sname [clause pats (normalB [|inject $val|]) []]]
                sequence $ sig ++ function
              genSig targs tname sname 0 miTp = (:[]) $ do
                fvar <- newName "f"
                hvar <- newName "h"
                avar <- newName "a"
                ivar <- newName "i"
                let targs' = init $ init targs
                    vars = hvar:fvar:avar:maybe [ivar] (const []) miTp++targs'
                    f = varT fvar
                    h = varT hvar
                    a = varT avar
                    i = varT ivar
                    ftype = foldl appT (conT tname) (map varT targs')
                    constr = (conT ''(:<:) `appT` ftype) `appT` f
                    typ = foldl appT (conT ''Cxt) [h, f, a, maybe i return miTp]
                    typeSig = forallT (map plainTV' vars) (sequence [constr]) typ
                sigD sname typeSig
              genSig _ _ _ _ _ = []
