module TaskList exposing
    ( TaskList
    , append
    , concat
    , empty
    , filter
    , fromMarkdown
    , map
    , parser
    , removeForFile
    , replaceForFile
    , taskContainingId
    , taskFromId
    , taskIds
    , taskTitles
    , tasks
    , topLevelTasks
    )

import List.Extra as LE
import Parser as P exposing (Parser)
import ParserHelper exposing (anyLineParser)
import TaskItem exposing (TaskItem)



-- TYPES


type TaskList
    = TaskList (List TaskItem)


empty : TaskList
empty =
    TaskList []



-- PARSING


parser : String -> Maybe String -> Parser TaskList
parser filePath fileDate =
    P.loop [] (taskItemsHelp filePath fileDate)
        |> P.map (\ts -> TaskList ts)


fromMarkdown : String -> Maybe String -> String -> TaskList
fromMarkdown filePath fileDate fileContents =
    P.run (parser filePath fileDate) (fileContents ++ "\n")
        |> Result.withDefault empty



-- COMBINE


append : TaskList -> TaskList -> TaskList
append (TaskList root) (TaskList toAppend) =
    TaskList <| root ++ toAppend


concat : List TaskList -> TaskList
concat =
    List.foldr append empty



-- MANIPULATE


map : (TaskItem -> TaskItem) -> TaskList -> TaskList
map fn (TaskList taskItems) =
    taskItems
        |> List.map fn
        |> TaskList


replaceForFile : String -> TaskList -> TaskList -> TaskList
replaceForFile filePath updatedList currentList =
    currentList
        |> removeForFile filePath
        |> append updatedList


removeForFile : String -> TaskList -> TaskList
removeForFile filePath (TaskList taskItems) =
    taskItems
        |> itemsNotFromFile filePath
        |> TaskList



-- INFO


filter : (TaskItem -> Bool) -> TaskList -> TaskList
filter fn (TaskList taskItems) =
    List.filter fn taskItems
        |> TaskList


taskTitles : TaskList -> List String
taskTitles (TaskList taskItems) =
    taskItems
        |> List.map TaskItem.title


taskIds : TaskList -> List String
taskIds (TaskList taskItems) =
    taskItems
        |> List.map TaskItem.id


taskContainingId : String -> TaskList -> Maybe TaskItem
taskContainingId id taskList =
    taskList
        |> tasks
        |> LE.find (TaskItem.containsId id)


taskFromId : String -> TaskList -> Maybe TaskItem
taskFromId id taskList =
    taskList
        |> tasks
        |> LE.find (\i -> TaskItem.id i == id)


tasks : TaskList -> List TaskItem
tasks (TaskList taskList) =
    taskList
        |> List.concatMap
            (\t -> t :: TaskItem.subtasks t)


topLevelTasks : TaskList -> List TaskItem
topLevelTasks (TaskList taskList) =
    taskList



-- PRIVATE


itemsNotFromFile : String -> List TaskItem -> List TaskItem
itemsNotFromFile pathToFile taskItems =
    taskItems
        |> List.filter (\t -> not (TaskItem.isFromFile pathToFile t))


taskItemsHelp : String -> Maybe String -> List TaskItem -> Parser (P.Step (List TaskItem) (List TaskItem))
taskItemsHelp filePath fileDate revTaskItems =
    P.oneOf
        [ P.backtrackable
            (TaskItem.parser filePath fileDate
                |> P.map (\taskItem -> P.Loop (taskItem :: revTaskItems))
            )
        , anyLineParser
            |> P.map (\_ -> P.Loop revTaskItems)
        , P.succeed ()
            |> P.map (\_ -> P.Done (List.reverse revTaskItems))
        ]
