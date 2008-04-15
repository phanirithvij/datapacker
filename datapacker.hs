{- 
Copyright (C) 2006-2008 John Goerzen <jgoerzen@complete.org>

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.
-}

{- |
   Module     : Main
   Copyright  : Copyright (C) 2008 John Goerzen
   License    : GNU GPL, version 3 or above; see COPYRIGHT for details

   Maintainer : John Goerzen <jgoerzen@complete.org>
   Stability  : provisional
   Portability: portable

Written by John Goerzen, jgoerzen\@complete.org

-}

import System.Log.Logger
import System.Log.Handler.Simple
import System.IO(stderr)
import System.Console.GetOpt.Utils
import System.Console.GetOpt
import System.Environment
import Data.Quantity
import Data.List
import System.Exit
import Control.Monad
import Types
import Text.Printf
import Scan

main = 
    do updateGlobalLogger "" (setLevel INFO)
       argv <- getArgs
       case getOpt RequireOrder options argv of
         (o, n, []) -> worker o n
         (_, _, errors) -> usageerror (concat errors) -- ++ usageInfo header options)
       
options = [Option "d" ["debug"] (NoArg ("d", "")) "Enable debugging",
           Option "p" ["preserve-order"] (NoArg ("p", ""))
                  "Don't reorder files for maximum packing",
           Option "s" ["size"] (ReqArg (stdRequired "s") "SIZE")
                  "Size of each output bin",
           Option "S" ["size-first"] (ReqArg (stdRequired "S") "SIZE")
                  "Override size of first output bin",
--           Option "0" ["null"] (NoArg ("0", ""))
--                  "Input items terminated by null character",
           Option "" ["help"] (NoArg ("help", "")) "Display this help"]

worker args files =
    do when (lookup "help" args == Just "") $ usageerror ""
       when (lookup "d" args == Just "") 
            (updateGlobalLogger "" (setLevel DEBUG))
       handler <- streamHandler stderr DEBUG
       updateGlobalLogger "" (setHandlers [handler])
       
       runinfo <- case parseArgs args files of
                       Left x -> usageerror x
                       Right x -> return x

       results <- scan runinfo files
       let numberedResults = zip [1..] (map (map snd) results)
       mapM_ printResult numberedResults

printResult :: (Integer, [FilePath]) -> IO ()
printResult (bin, fpl) =
    mapM_ (\fp -> printf "%03d\t%s\n" bin fp) fpl
   
parseArgs args files =
    do size <- case lookup "s" args of
                 Nothing -> fail "Missing required argument --size"
                 Just x -> parseNumInt binaryOpts True x
       first <- case lookup "S" args of
                  Nothing -> return size
                  Just x -> parseNumInt binaryOpts True x
       let po = case lookup "p" args of
                  Nothing -> False
                  Just _ -> True
       return $ RunInfo {binSize = size, firstBinSize = first,
                         preserveOrder = po}
    
usageerror errormsg =
    do putStrLn errormsg
       putStrLn (usageInfo header options)
       exitFailure

header = "Usage: datapacker [options] --size=n inputfiles\n\n\
         \Available options are:\n"
