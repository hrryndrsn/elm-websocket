port module Main exposing (Model, Msg(..), activeUsers, cache, init, main, update, view)

import Browser
import Html exposing (Html, button, div, h1, img, text)
import Html.Attributes exposing (src)
import Html.Events exposing (onClick)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (hardcoded, optional, required)
import Json.Encode as E



-- port out


port cache : E.Value -> Cmd msg



--port In


port activeUsers : (E.Value -> msg) -> Sub msg



---- MODEL ----


type alias Model =
    { counter : Int
    , activeUsers : String
    }


type alias WindowEvent =
    { user : String }


init : ( Model, Cmd Msg )
init =
    ( { counter = 0, activeUsers = "none" }, Cmd.none )



---- UPDATE ----


type Msg
    = SendCache
    | Changed E.Value
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

                throwAway =
                    Debug.log "pv: " pv
            in
            case pv of
                Ok windowEvent ->
                    ( { model | activeUsers = windowEvent.user }, Cmd.none )

                Err error ->
                    let
                        errorMessage =
                            handleDecodeError error
                    in
                    ( model, Cmd.none )

        -- in
        -- ( { model | activeUsers = "Error Parsing value in update" }, Cmd.none )
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
        , subscriptions = subscriptions
        }



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    activeUsers Changed



-- DECODERS
--deoces a value to a stirng
--returns a result which is a decode error or a string


parseVal : E.Value -> Result.Result Decode.Error WindowEvent
parseVal value =
    Decode.decodeValue windowEventDecoder value


windowEventDecoder : Decode.Decoder WindowEvent
windowEventDecoder =
    Decode.succeed WindowEvent
        |> optional "user" Decode.string "did not make it"
