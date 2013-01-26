{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
import Control.Applicative
import Data.Map                       hiding (map)
import Data.Maybe
import Data.Text                      hiding (length)
import Data.Time
import Data.Time.Clock.POSIX
import Database.SQLite.Simple
import Database.SQLite.Simple.FromRow
import Prelude                        hiding (unlines, writeFile)
import System.Environment
import System.Locale
import Text.Hamlet.XML
import Text.XML

data SMS = SMS {
    storage_time :: Int
  , start_time   :: Int
  , end_time     :: Maybe Int
  , is_read      :: Maybe Int
  , outgoing     :: Maybe Bool
  , remote_uid   :: Maybe Text
  , free_text    :: Maybe Text
  , remote_name  :: Maybe Text
  } deriving (Show)

instance FromRow SMS where
  fromRow = SMS <$> field <*> field <*> field <*> field <*> field <*> field <*> field <*> field

querytext = Query $ unlines
  ["SELECT Events.storage_time" -- not null
  ,"     , Events.start_time"   -- not null
  ,"     , Events.end_time"
  ,"     , Events.is_read"
  ,"     , Events.outgoing"
  ,"     , Events.remote_uid"
  ,"     , Events.free_text"
  ,"     , Remotes.remote_name"
  ,"FROM   Events,Remotes"
  ,"WHERE"
  ,"       Events.event_type_id = 11"
  ,"   AND Events.local_uid     = Remotes.local_uid"
  ,"   AND Events.remote_uid    = Remotes.remote_uid"
  ,"ORDER  BY start_time"]

main = do
  file:[] <- getArgs
  conn <- open file
  smslist <- query_ conn querytext :: IO [SMS]
  writeFile def {rsPretty = False} "output.xml" $ smslist2xml smslist
  close conn

smslist2xml smslist = Document prologue root []
  where prologue = Prologue [MiscInstruction Instruction {instructionTarget = "xml-stylesheet", instructionData = "type=\"text/xsl\" href=\"sms.xsl\""}] Nothing []
        root = Element "smses" elemAttribs nodes
        elemAttribs = fromList [(Name {nameLocalName = "count", nameNamespace = Nothing, namePrefix = Nothing},numofsms)]
        numofsms = (pack . show) (length smslist)
        nodes = [xml|$forall sms <- smslist
                           <sms protocol="0"
                                address=#{justOrBlank (remote_uid sms)}
                                   date=#{x1000 (start_time sms)}
                                   type=#{type' sms}
                                subject="null"
                                   body=#{justOrBlank (free_text sms)}
                                    toa="null"
                                 sc_toa="null"
                         service_center="null"
                                   read="1"
                                 status="-1"
                                 locked="0"
                              date_sent=#{x1000maybe (end_time sms)}
                          readable_date=#{readableDate (start_time sms)}
                           contact_name=#{justOrBlank (remote_name sms)} > |]
        justOrBlank = fromMaybe ""
        x1000maybe = maybe "0" x1000
        x1000 x = pack $ if x == 0 then "0" else show x ++ "000"
        type' sms = case outgoing sms of Just True -> "2" -- 1 received, 2 sent, 3 drafts?
                                         _         -> "1"
        readableDate = pack . formatTime defaultTimeLocale "%c" . posixSecondsToUTCTime . realToFrac
