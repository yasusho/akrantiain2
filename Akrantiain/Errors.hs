{-# OPTIONS -Wall -fno-warn-unused-do-bind #-}

module Akrantiain.Errors
(SemanticError(..)
,RuntimeError(..)
,ModuleError(..)
,SemanticWarning(..)
,RuntimeWarning(..)
,ModuleWarning(..)
,SemanticMsg
,RuntimeMsg
,ModuleMsg
,mapM2
,mapM3
,lift,tell
) where
import Prelude hiding (undefined)
import Data.Either(lefts,rights)
import Control.Monad.Writer

data SemanticError = E {errNum :: Int, errStr :: String} deriving(Eq, Ord)
instance Show SemanticError where
 show E{errNum = n, errStr = str} = "Semantic error (error code #" ++ show n ++ ")\n" ++ str

data RuntimeError = RE {errNo :: Int, errMsg :: String} deriving(Eq, Ord)
instance Show RuntimeError where
 show RE{errNo = n, errMsg = str} = "Runtime error (error code #" ++ show n ++ ")\n" ++ str

data ModuleError = ME{errorNo :: Int, errorMsg :: String} deriving(Eq, Ord)
instance Show ModuleError where
 show ME{errorNo = n, errorMsg = str} = "Module error (error code #" ++ show n ++ ")\n" ++ str

-- similar to mapM but keeps track of all errors
mapM2 :: (d -> Either c b) -> [d] -> Either [c] [b]
mapM2 f ds = let{es = map f ds; (ls,rs) = (lefts es, rights es)} in
 case ls of
  [] -> Right rs
  _ -> Left ls

-- similar to mapM but keeps track of all warnings
mapM3 :: (Monoid e) => (d -> WriterT e (Either c) b) -> [d] -> WriterT e (Either [c]) [b]
mapM3 f ds = WriterT tmp where 
 tmp = do -- Either [c] ([b], e)
  bes <- mapM2 (runWriterT . f) ds -- Either [c] [(b,e)]
  return (map fst bes, mconcat $ map snd bes)
 
 

data SemanticWarning = SemanticWarning {warnNum   :: Int, warnStr    :: String} deriving(Eq, Ord)
instance Show SemanticWarning where
 show SemanticWarning{warnNum = n, warnStr = str} = "Semantic warning (warning code #" ++ show n ++ ")\n" ++ str

data RuntimeWarning  = RuntimeWarning  {warnNo    :: Int, warnMsg    :: String} deriving(Eq, Ord)
instance Show RuntimeWarning where
 show RuntimeWarning{warnNo = n, warnMsg = str} = "Runtime warning (warning code #" ++ show n ++ ")\n" ++ str

data ModuleWarning   = ModuleWarning   {warningNo :: Int, warningMsg :: String} deriving(Eq, Ord)
instance Show ModuleWarning where
 show ModuleWarning{warningNo = n, warningMsg = str} = "Module warning (warning code #" ++ show n ++ ")\n" ++ str

type SemanticMsg a = WriterT [SemanticWarning] (Either SemanticError) a
type RuntimeMsg  a = WriterT [RuntimeWarning]  (Either RuntimeError ) a
type ModuleMsg   a = WriterT [ModuleWarning]   (Either ModuleError  ) a
