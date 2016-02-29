module Row where

import Control.Arrow
import Data.Functor.Both as Both
import Line

-- | A row in a split diff, composed of a before line and an after line.
data Row a = Row { unLeft :: !(Line a), unRight :: !(Line a) }
  deriving (Eq, Functor)

-- | Return a tuple of lines from the row.
unRow :: Row a -> Both (Line a)
unRow (Row a b) = Both (a, b)

-- | Map over both sides of a row with the given functions.
wrapRowContents :: Both ([a] -> b) -> Row a -> Row b
wrapRowContents transform row = uncurry Row . runBoth $ wrapLineContents <$> transform <*> unRow row

-- | Given functions that determine whether an item is open, add a row to a
-- | first open, non-empty item in a list of rows, or add it as a new row.
adjoinRowsBy :: MaybeOpen a -> MaybeOpen a -> [Row a] -> Row a -> [Row a]
adjoinRowsBy _ _ [] row = [row]

adjoinRowsBy f g rows (Row left' right') | Both (Just _, Just _) <- openLineBy <$> Both (f, g) <*> (Both.unzip $ unRow <$> rows) = Both.zipWith Row $ both <*> Both (left', right')
  where both = adjoinLinesBy <$> Both (f, g) <*> (Both.unzip $ unRow <$> rows)

adjoinRowsBy f _ rows (Row left' right') | Just _ <- openLineBy f $ unLeft <$> rows = case right' of
  EmptyLine -> rest
  _ -> Row EmptyLine right' : rest
  where rest = Prelude.zipWith Row (lefts left') rights
        (lefts, rights) = first (adjoinLinesBy f) . runBoth $ Both.unzip $ unRow <$> rows

adjoinRowsBy _ g rows (Row left' right') | Just _ <- openLineBy g $ unRight <$> rows = case left' of
  EmptyLine -> rest
  _ -> Row left' EmptyLine : rest
  where rest = Prelude.zipWith Row lefts (rights right')
        (lefts, rights) = second (adjoinLinesBy g) . runBoth $ Both.unzip $ unRow <$> rows

adjoinRowsBy _ _ rows row = row : rows


instance Show a => Show (Row a) where
  show (Row left right) = "\n" ++ show left ++ " | " ++ show right
