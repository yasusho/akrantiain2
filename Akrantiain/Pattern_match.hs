{-# OPTIONS -Wall -fno-warn-unused-do-bind #-}
module Akrantiain.Pattern_match
(cook
) where
import Prelude hiding (undefined)
import Data.Maybe(mapMaybe, isNothing, catMaybes)
import Data.List(isPrefixOf, inits, tails, intercalate)
import Data.Char(toLower)
import Data.Either(lefts, rights)
import Control.Monad(guard)
import Akrantiain.Errors
import Akrantiain.Rule
import Akrantiain.Structure(Choose(..))
import Akrantiain.NFD
import qualified Data.Set as S
import Control.Arrow(first)
import Control.Monad.Reader

type StatElem = (String, Maybe String)
type Stat = [StatElem]
type StatPair = (Stat, Stat)

resolvePunctuation :: Environment -> StatElem -> Either String String
resolvePunctuation _ (_, Just b) = Right b
resolvePunctuation env (a, Nothing)
 | isSpPunct (pun env) a = Right " "
 | FALL_THROUGH `S.member` bools env = Right a 
 | otherwise = Left a

insensitive :: Rule -> Rule
insensitive R{leftneg=l, middle=m, rightneg=r} = R{leftneg=fmap f l, middle=map(first h<$>) m, rightneg=fmap f r} where
 f :: Condition -> Condition
 f (Negation c) = Negation $ h c
 f NegBoundary = NegBoundary
 h :: Choose String -> Choose String
 h (Ch arr) = Ch . map (map toLower) $ arr
-- R{leftneg :: Maybe(Condition), middle :: [ Either Boundary_ (Choose String, W)], rightneg :: Maybe(Condition)}


cook :: Rules -> String -> Either RuntimeError String
cook (env,rls') str_ = do
 let str = if S.member USE_NFD (bools env) then nfd str_ else str_
 let (rls,stat) = case CASE_SENSITIVE `S.member` bools env of{
   True -> (rls', map (\x -> ([x], Nothing)) (" " ++ str ++ " ")); -- extra spaces required for handling word boundary
   False -> (map insensitive rls', map (\x -> ([toLower x], Nothing)) (" " ++ str ++ " ")) }
 let cooked = cook' rls stat `runReader` env
 let eitherList = map (resolvePunctuation env) cooked
 case lefts eitherList of
  [] -> do
   let ans = dropTwo $ concat $ rights eitherList
   if USE_NFD `S.member` bools env then return $ nfc ans else return ans
  strs -> do
   let msg = "{" ++ intercalate "}, {" strs ++ "}"
   Left RE{errNo = 210, errMsg = "no rules that can handle character(s) "++ msg} -- FIXME: better message that lets the user know which `r` made akrantiain crash

dropTwo :: String -> String
dropTwo = dropOne . reverse . dropOne . reverse
 where dropOne = \(' ':xs) -> xs -- GUARANTEED TO BE SAFE

cook' :: [Rule] -> Stat -> Reader Environment Stat
cook' rls stat = foldM apply stat rls

-- merge is allowed, split is not
apply :: Stat -> Rule -> Reader Environment Stat
apply stat rule = do
 frontback_array <- match rule stat
 case frontback_array of
  [] -> return stat
  c -> let (a,b) = last c in do
   newStat <- apply a rule
   return $ newStat ++ b




-- cutlist [1,2,3] = [([],[1,2,3]),([1],[2,3]),([1,2],[3]),([1,2,3],[])]
cutlist :: [a] -> [([a],[a])]
cutlist [] = [([],[])]
cutlist u@(x:xs) =  ([],u): map f (cutlist xs) where f(a,b) = (x:a,b)



rev2 ::  [([a], t)] -> [([a], t)]
rev2 = map (first reverse) . reverse

upgrade :: ([a] -> Bool) -> ([a] -> Bool)
upgrade f str = all f $ tail $ inits str

upgrade2 :: ([a] -> Bool) -> ([a] -> Bool)
upgrade2 f str = all f $ init $ tails str

unCond :: Condition -> (Punctuation -> String -> Bool)
unCond (Negation c) = \_ -> no c
unCond NegBoundary = \punct str -> not(isSpPunct punct str)


match :: Rule -> Stat -> Reader Environment [StatPair]

match R{leftneg=Nothing, middle =[], rightneg=Nothing} stat = return $ cutlist stat

match R{leftneg=Nothing, middle=[], rightneg=Just condition} stat = do
 env <- ask
 let punct = pun env
 return $ filter (f punct) $ cutlist stat where
  f p (_, back) = upgrade (unCond condition p) $ concatMap fst back

match k@R{leftneg=Nothing, middle=Right(Ch pats,w):xs} stat =  do
 newMatch <- match k{middle=xs} stat
 return $ catMaybes [testPattern w fb pat | fb <- newMatch, pat <- pats]
match k@R{leftneg=Nothing, middle=Left():xs} stat = do
 newMatch <- match k{middle=xs} stat
 env <- ask
 return $ mapMaybe (h env) newMatch where
 h env (front, back) = do
  let front' = reverse front
  let punct = pun env
  let tmp = map(isSpPunct punct) $ filter (/="") $ map fst front'
  guard $ null tmp || head tmp
  let (b', f'') = span (isSpPunct punct . fst) front'
  return (reverse f'', reverse b' ++ back)

match k@R{leftneg=Just condition} stat = do
 newMatch <- match k{leftneg=Nothing} stat
 env <- ask
 let punct = pun env
 let f (front, _) = upgrade2 (unCond condition punct) $ concatMap fst front
 return $ filter f newMatch



testPattern :: W -> StatPair -> String -> Maybe StatPair
testPattern w (front, back) pat = do
 let front' = rev2 front
 let pat' = reverse pat
 taken <- takeTill pat' front'
 let taken' = rev2 taken
 case w of
  W w' -> do
   guard $ all (isNothing . snd) taken'
   return (rev2 $ drop(length taken')front', (pat,Just w') : back)
  Dollar_ -> return (rev2 $ drop(length taken')front', taken' ++ back)

-- String -> Stat -> Maybe Stat
takeTill :: (Eq b) => [b] -> [([b],a)] -> Maybe [([b], a)]
takeTill [] _ = Just []
takeTill _ [] = Nothing
takeTill str (x@(s,_):xs)
 | s `isPrefixOf` str = (x:) <$> takeTill (drop(length s)str) xs
 | otherwise = Nothing
