{-# LANGUAGE OverloadedStrings, RecordWildCards #-}
module Data.Loc
( Loc(..)
, Path(..)
, interactive
, here
, stackLoc
) where

import Data.Text (Text, pack)
import GHC.Stack
import Source.Span

newtype Path = Path { getPath :: Text }
  deriving (Eq, Ord, Show)

data Loc = Loc
  { locPath :: !Path
  , locSpan :: {-# UNPACK #-} !Span
  }
  deriving (Eq, Ord, Show)

interactive :: Loc
interactive = Loc (Path "<interactive>") (Span (Pos 1 1) (Pos 1 1))


here :: HasCallStack => Maybe (Path, Span)
here = stackLoc callStack

stackLoc :: CallStack -> Maybe (Path, Span)
stackLoc cs = case getCallStack cs of
  (_, srcLoc):_ -> Just (fromGHCSrcLoc srcLoc)
  _             -> Nothing

fromGHCSrcLoc :: SrcLoc -> (Path, Span)
fromGHCSrcLoc SrcLoc{..} = (Path (pack srcLocFile), Span (Pos srcLocStartLine srcLocStartCol) (Pos srcLocEndLine srcLocEndCol))
