port module Main exposing (Model, Msg(..), cache, init, main, update, view, window)

import Browser
import Html exposing (Html, button, div, h1, img, p, text)
import Html.Attributes exposing (src)
import Html.Events exposing (onClick)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (hardcoded, optional, required)
import Json.Encode as E
import Svg exposing (circle, rect, svg, text)
import Svg.Attributes exposing (cx, cy, fill, height, r, rx, ry, viewBox, width, x, y)
import Svg.Events exposing (onClick)
import Time exposing (..)



-- port out


port cache : E.Value -> Cmd msg



--port In


port window : (E.Value -> msg) -> Sub msg



---- MODEL ----


type alias Model =
    { counter : Int
    , window : WindowEvent
    , time : Time.Posix
    }


type alias WindowEvent =
    { width : Int
    , height : Int
    }


init : ( Model, Cmd Msg )
init =
    ( { counter = 0, window = { width = 5, height = 5 }, time = Time.millisToPosix 0 }, Cmd.none )



---- UPDATE ----


type Msg
    = SendCache
    | Changed E.Value
    | ClickedSvg
    | Tick Time.Posix
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SendCache ->
            ( { model | counter = model.counter + 1 }
            , cache (E.int (model.counter + 1))
            )

        Changed value ->
            let
                pv =
                    parseVal value
            in
            case pv of
                Ok windowEvent ->
                    ( { model | window = windowEvent }, Cmd.none )

                Err error ->
                    let
                        errorMessage =
                            handleDecodeError error
                    in
                    ( model, Cmd.none )

        ClickedSvg ->
            ( { model | counter = model.counter + 1 }
            , cache (E.int (model.counter + 1))
            )

        -- in
        -- ( { model | window = "Error Parsing value in update" }, Cmd.none )
        Tick newTime ->
            ( { model | time = newTime }
            , Cmd.none
            )

        NoOp ->
            ( model, Cmd.none )


handleDecodeError : Decode.Error -> String
handleDecodeError error =
    case error of
        Decode.Field str errr ->
            "Field Error"

        Decode.Index int err ->
            "Index Error"

        Decode.OneOf errList ->
            "List of Errors"

        Decode.Failure str val ->
            "Failure error"



---- VIEW ----


view : Model -> Html Msg
view model =
    div []
        [ div []
            [ renderSvg ( model.window.width, model.window.height )
            ]
        ]


renderPlainPage : Int -> Int -> Html.Html Msg
renderPlainPage width height =
    div []
        [ img [ src "/logo.svg" ] []
        , h1 [] [ text "Your Elm App is working!" ]
        , p []
            [ text "window.width: "
            , text (String.fromInt width)
            ]
        , p []
            [ text " window.height: "
            , text (String.fromInt height)
            ]
        , button [ onClick SendCache ] [ text "cache" ]
        ]


renderSvg : ( Int, Int ) -> Html.Html Msg
renderSvg ( w, h ) =
    let
        stringWidth =
            String.fromInt w

        stringHeight =
            String.fromInt h

        halfW =
            String.fromFloat (toFloat w / 2)

        halfH =
            String.fromFloat (toFloat h / 2)
    in
    svg
        [ width stringWidth, height stringHeight, viewBox ("0 0" ++ " " ++ stringWidth ++ " " ++ stringHeight), fill "white" ]
        [ Svg.text_ [ fill "black", x "20", y "35" ] [ Svg.text (stringWidth ++ " " ++ stringHeight) ]
        , circle [ onClick ClickedSvg, cx halfW, cy halfH, r "150", fill "black" ] []
        ]



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = subscriptions
        }



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch [ window Changed, Time.every 1000 Tick ]



-- DECODERS
--deoces a value to a stirng
--returns a result which is a decode error or a string


parseVal : E.Value -> Result.Result Decode.Error WindowEvent
parseVal value =
    Decode.decodeValue windowEventDecoder value


windowEventDecoder : Decode.Decoder WindowEvent
windowEventDecoder =
    Decode.succeed WindowEvent
        |> optional "width" Decode.int 0
        |> optional "height" Decode.int 0
