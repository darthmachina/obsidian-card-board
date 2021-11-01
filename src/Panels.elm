module Panels exposing
    ( Panels
    , cards
    , currentIndex
    , init
    , length
    , panels
    , tabTitles
    )

import Card exposing (Card)
import CardBoardConfig
import Panel exposing (Panel)
import SafeZipper exposing (SafeZipper)
import TaskList exposing (TaskList)
import TimeWithZone exposing (TimeWithZone)



-- TYPES


type Panels
    = Panels (SafeZipper CardBoardConfig.Config) TaskList



-- CONSTRUCTION


init : SafeZipper CardBoardConfig.Config -> TaskList -> Panels
init configs taskList =
    Panels configs taskList



-- INFO


panels : Panels -> SafeZipper Panel
panels (Panels configs taskList) =
    SafeZipper.indexedMapSelectedAndRest (panel taskList) (panel taskList) configs


tabTitles : Panels -> SafeZipper String
tabTitles (Panels configs _) =
    SafeZipper.indexedMapSelectedAndRest tabTitle tabTitle configs


cards : TimeWithZone -> Panels -> List Card
cards timeWithZone ps =
    ps
        |> panels
        |> SafeZipper.toList
        |> List.indexedMap (Panel.columns timeWithZone)
        |> List.concat
        |> List.map Tuple.second
        |> List.concat


currentIndex : Panels -> Maybe Int
currentIndex (Panels config _) =
    SafeZipper.selectedIndex config


length : Panels -> Int
length (Panels config _) =
    SafeZipper.length config



-- PRIVATE


tabTitle : Int -> CardBoardConfig.Config -> String
tabTitle _ config =
    case config of
        CardBoardConfig.DateBoardConfig dateBoardConfig ->
            dateBoardConfig.title

        CardBoardConfig.TagBoardConfig tagBoardConfig ->
            tagBoardConfig.title


panel : TaskList -> Int -> CardBoardConfig.Config -> Panel
panel taskList _ config =
    Panel.init config taskList
