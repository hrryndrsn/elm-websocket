port module Main exposing (Model, Msg(..), cache, init, main, update, view)

import Browser
import Html exposing (Html, button, div, h1, img, text)
import Html.Attributes exposing (src)
import Html.Events exposing (onClick)
import Json.Encode as E


port cache : E.Value -> Cmd msg



---- MODEL ----


type alias Model =
    { counter : Int }


init : ( Model, Cmd Msg )
init =
    ( { counter = 0 }, Cmd.none )



---- UPDATE ----


type Msg
    = SendCache
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( { model | counter = model.counter + 1 }
    , cache (E.int (model.counter + 1))
    )



---- VIEW ----


view : Model -> Html Msg
view model =
    div []
        [ img [ src "/logo.svg" ] []
        , h1 [] [ text "Your Elm App is working!" ]
        , button [ onClick SendCache ] [ text "cache" ]
        ]



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = always Sub.none
        }
