port module Main exposing (Model, Msg(..), cache, init, main, receiveSnapshot, receiveUpdate, update, view, window)

import Browser
import Html exposing (Html, button, div, h1, h2, img, input, li, p, text, ul)
import Html.Attributes exposing (class, src)
import Html.Events exposing (onClick, onInput)
import Html.Lazy exposing (lazy, lazy2)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (hardcoded, optional, required)
import Json.Encode as E
import Svg exposing (rect, svg)
import Svg.Attributes exposing (fill, height, width, x, y)
import Time exposing (..)



-- port out


port cache : E.Value -> Cmd msg


port sendWS : E.Value -> Cmd msg



--port In


port window : (E.Value -> msg) -> Sub msg


port receiveSnapshot : (E.Value -> msg) -> Sub msg


port receiveUpdate : (E.Value -> msg) -> Sub msg



---- MODEL ----


type alias Model =
    { counter : Int
    , window : WindowEvent
    , inputText : String
    , orderBook : OrderBook
    }


type alias WindowEvent =
    { width : Int
    , height : Int
    }


type alias WSMessageOut =
    String


type alias WSMessageIn =
    String


type alias Snapshot =
    { productID : String
    , asks : List Order
    , bids : List Order
    }


type alias MarketUpdate =
    { product_id : String
    , time : String
    , changes : List ChangesPacket
    }


type alias ChangesPacket =
    List String


type alias Changes =
    List Change


type alias Change =
    { side : String
    , price : Float
    , size : Float
    }


type alias Order =
    List String


type alias FloatOrder =
    List Float


type alias OrderBook =
    { productId : String
    , asks : List FloatOrder
    , bids : List FloatOrder
    }


init : ( Model, Cmd Msg )
init =
    ( { counter = 0
      , window = { width = 5, height = 5 }
      , inputText = ""
      , orderBook =
            { productId = "empty"
            , asks = []
            , bids = []
            }
      }
    , Cmd.none
    )



---- UPDATE ----


type Msg
    = SendCache
    | SendWS WSMessageOut
    | Changed E.Value
    | ReceiveUpdate E.Value
    | ReceiveSnapshot E.Value
    | ChangedInput String
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SendCache ->
            ( { model | counter = model.counter + 1 }
            , cache (E.int (model.counter + 1))
            )

        SendWS str ->
            ( model
            , sendWS (E.string str)
            )

        Changed value ->
            let
                pv =
                    parseVal value
            in
            case pv of
                Ok windowEvent ->
                    ( { model
                        | window = windowEvent
                      }
                    , Cmd.none
                    )

                Err error ->
                    let
                        errorMessage =
                            handleDecodeError error
                    in
                    ( model, Cmd.none )

        ReceiveUpdate value ->
            let
                pv =
                    parseChangesPacket value
            in
            case pv of
                Ok packet ->
                    -- Packet decoding was successful
                    let
                        changes =
                            packet.changes

                        -- map over the string list and convert the changes into values we can work with
                        convertedChanges =
                            List.map deconstructChangeList changes

                        -- for each change, we want to update either the ask array
                        updateAsks =
                            List.map (\change -> updateOrderBook change model.orderBook.asks) convertedChanges

                        -- for each change, we want to update either the bid  array
                        updateBids =
                            List.map (\change -> updateOrderBook change model.orderBook.bids) convertedChanges

                        oldOrderBook =
                            model.orderBook

                        newAsks =
                            case lastElem updateAsks of
                                Just list ->
                                    list

                                Nothing ->
                                    []

                        newBids =
                            case lastElem updateBids of
                                Just list ->
                                    list

                                Nothing ->
                                    []

                        newOrderBook =
                            { oldOrderBook
                                | asks = newAsks
                                , bids = newBids
                            }

                        newBook =
                            OrderBook model.orderBook.productId
                    in
                    ( { model | orderBook = newOrderBook }
                    , Cmd.none
                    )

                Err error ->
                    let
                        errorMessage =
                            handleDecodeError error

                        throwaway =
                            Debug.log "Error Decoding!" errorMessage
                    in
                    ( model, Cmd.none )

        ReceiveSnapshot value ->
            let
                pv =
                    parseWSSnapshot value
            in
            case pv of
                Ok snapshot ->
                    let
                        floatAsks =
                            List.map parseFloatOrder snapshot.asks

                        floatBids =
                            List.map parseFloatOrder snapshot.bids

                        newOrderBook =
                            OrderBook snapshot.productID floatAsks floatBids
                    in
                    ( { model
                        | orderBook = newOrderBook
                      }
                    , Cmd.none
                    )

                Err error ->
                    let
                        errorMessage =
                            handleDecodeError error

                        throwaway =
                            Debug.log "Error Decoding!" errorMessage
                    in
                    ( model, Cmd.none )

        ChangedInput str ->
            ( { model | inputText = str }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


lastElem : List a -> Maybe a
lastElem =
    List.foldl (Just >> always) Nothing


updateOrderBook : Change -> List FloatOrder -> List FloatOrder
updateOrderBook change list =
    List.map (\order -> comparePrice change order) list


comparePrice : Change -> List Float -> List Float
comparePrice change order =
    let
        orderPrice =
            findHead order

        size =
            findEnd order
    in
    case change.price == orderPrice of
        True ->
            [ orderPrice, change.size ]

        False ->
            order


deconstructChangeList : ChangesPacket -> Change
deconstructChangeList packet =
    case packet of
        a :: b :: c ->
            let
                fb =
                    extractFloat [ b ]

                fc =
                    extractFloat c

                derp =
                    Debug.log "x"
            in
            Change a fb fc

        -- destructor the array like this?
        x ->
            Change "empty" 0.0 0.0


extractFloat : List String -> Float
extractFloat list =
    let
        tryHead =
            List.head list
    in
    case tryHead of
        Just string ->
            let
                tryConv =
                    String.toFloat string
            in
            case tryConv of
                Just float ->
                    float

                Nothing ->
                    0.0

        Nothing ->
            0.0


handleDecodeError : Decode.Error -> String
handleDecodeError error =
    case error of
        Decode.Field str err ->
            "Field Error: " ++ str ++ Decode.errorToString err

        Decode.Index int err ->
            "Index Error" ++ String.fromInt int ++ Decode.errorToString err

        Decode.OneOf errList ->
            "List of Errors"

        Decode.Failure str val ->
            "Failure error"



---- VIEW ----


view : Model -> Html Msg
view model =
    div []
        [ lazy renderHeader model.orderBook.productId
        , div
            [ class "orderbook" ]
            [ lazy2 renderTable "asks" model.orderBook.asks
            , lazy2 renderTable "bids" model.orderBook.bids
            ]
        ]


renderHeader : String -> Html msg
renderHeader productId =
    div [ class "header" ]
        [ h2 [] [ text productId ] ]


renderTable : String -> List FloatOrder -> Html sg
renderTable name list =
    div [ class name ]
        [ div [ class "title" ] [ text name ]
        , div [ class "table" ] (List.map renderOrderList list)
        ]


renderOrderList : FloatOrder -> Html msg
renderOrderList order =
    let
        price =
            findHead order

        size =
            findEnd order
    in
    div [ class "row" ]
        [ div []
            [ text "price: "
            , text (String.fromFloat price)
            ]
        , div []
            [ text " size: "
            , text (String.fromFloat size)
            ]
        ]


findHead : List Float -> Float
findHead floatList =
    let
        tryHead =
            List.head floatList
    in
    case tryHead of
        Just float ->
            float

        Nothing ->
            0.0


findEnd : List Float -> Float
findEnd floatList =
    let
        tryTail =
            List.tail floatList
    in
    case tryTail of
        Just list ->
            let
                end =
                    List.head list
            in
            case end of
                Just float ->
                    float

                Nothing ->
                    0.0

        Nothing ->
            0.0


renderPlainPage : String -> List String -> Html Msg
renderPlainPage inputText chatStream =
    div []
        [ h1 []
            [ text
                "websocket fun"
            ]
        , div []
            (List.map (\chatString -> p [] [ text chatString ]) chatStream
                |> List.reverse
            )
        , div []
            [ input [ onInput ChangedInput ] []
            , button [ onClick (SendWS inputText) ] [ text " send ws" ]
            ]
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



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ window Changed
        , receiveUpdate ReceiveUpdate
        , receiveSnapshot ReceiveSnapshot
        ]



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


parseWSVal : E.Value -> Result.Result Decode.Error String
parseWSVal value =
    Decode.decodeValue Decode.string value


orderDecoder : Decode.Decoder Order
orderDecoder =
    Decode.list Decode.string


orderListDecoder : Decode.Decoder (List Order)
orderListDecoder =
    Decode.list orderDecoder


snapshotDecoder : Decode.Decoder Snapshot
snapshotDecoder =
    Decode.succeed Snapshot
        |> required "product_id" Decode.string
        |> required "asks" (Decode.list orderDecoder)
        |> required "bids" orderListDecoder


parseWSSnapshot : E.Value -> Result.Result Decode.Error Snapshot
parseWSSnapshot snap =
    Decode.decodeValue snapshotDecoder snap


parseFloatOrder : Order -> List Float
parseFloatOrder order =
    let
        strList =
            returnStrList order
    in
    List.map parseFloat strList


returnStrList : Order -> List String
returnStrList order =
    List.map (\o -> o) order


parseFloat : String -> Float
parseFloat str =
    let
        tryFloat =
            String.toFloat str
    in
    case tryFloat of
        Just float ->
            float

        Nothing ->
            0.0



-- Changes decoders


marketUpdateDecoder : Decode.Decoder MarketUpdate
marketUpdateDecoder =
    Decode.succeed MarketUpdate
        |> required "product_id" Decode.string
        |> required "time" Decode.string
        |> required "changes" (Decode.list changesPacketDecoder)


changesPacketDecoder : Decode.Decoder ChangesPacket
changesPacketDecoder =
    Decode.list Decode.string


parseChangesPacket : E.Value -> Result.Result Decode.Error MarketUpdate
parseChangesPacket packet =
    Decode.decodeValue marketUpdateDecoder packet
