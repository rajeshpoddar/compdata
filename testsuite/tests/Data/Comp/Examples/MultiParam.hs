{-# LANGUAGE TypeOperators #-}
module Data.Comp.Examples.MultiParam where

import qualified Examples.MultiParam.Eval as Eval
import qualified Examples.MultiParam.EvalI as EvalI
import qualified Examples.MultiParam.EvalM as EvalM
import qualified Examples.MultiParam.EvalAlgM as EvalAlgM
import qualified Examples.MultiParam.DesugarEval as DesugarEval
import qualified Examples.MultiParam.DesugarPos as DesugarPos
import qualified Examples.MultiParam.FOL as FOL

import Data.Comp.MultiParam

import Test.Framework
import Test.Framework.Providers.QuickCheck2
import Test.QuickCheck
import Test.Utils





--------------------------------------------------------------------------------
-- Test Suits
--------------------------------------------------------------------------------

tests = testGroup "Parametric Compositional Data Types" [
         testProperty "eval" evalTest,
         testProperty "evalI" evalITest,
         testProperty "evalM" evalMTest,
         testProperty "evalAlgM" evalAlgMTest,
         testProperty "desugarEval" desugarEvalTest,
         testProperty "desugarPos" desugarPosTest
--         testProperty "fol" folTest
        ]


--------------------------------------------------------------------------------
-- Properties
--------------------------------------------------------------------------------

instance (EqHD f, Eq p) => EqHD (f :&: p) where
    eqHD (v1 :&: p1) (v2 :&: p2) = do b <- eqHD v1 v2
                                      return $ p1 == p2 && b

evalTest = Eval.evalEx == Just (Term $ Eval.iConst 4)
evalITest = EvalI.evalEx == 4
evalMTest = EvalM.evalMEx == Just (Term $ EvalM.iConst 12)
evalAlgMTest = EvalAlgM.evalMEx == Just (Term $ EvalAlgM.iConst 5)
desugarEvalTest = DesugarEval.evalEx == Just (Term $ DesugarEval.iConst (-6))
desugarPosTest = DesugarPos.desugPEx ==
                 Term (DesugarPos.iAApp (DesugarPos.Pos 1 0)
                                        (DesugarPos.iALam (DesugarPos.Pos 1 0) $ \x -> DesugarPos.iAMult (DesugarPos.Pos 1 2) (DesugarPos.iAConst (DesugarPos.Pos 1 2) (-1)) x)
                                        (DesugarPos.iAConst (DesugarPos.Pos 1 1) 6))
{-folTest = show FOL.foodFact7 == "(Person(x1) and Food(x2)) -> (Food(Skol2(x1)) or Person(Skol6(x2)))\n" ++
          "(Person(x1) and Food(x2)) -> (Food(Skol2(x1)) or Eats(Skol6(x2), x2))\n" ++
                                                                                        "(Person(x1) and Eats(x1, Skol2(x1)) and Food(x2)) -> (Person(Skol6(x2)))\n" ++
                                                                                        "(Person(x1) and Eats(x1, Skol2(x1)) and Food(x2)) -> (Eats(Skol6(x2), x2))"-}