// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

/**
 * @author René Hochmuth
 */

/**
 * @dev priceFeed contract for sDAI token.
 * Takes chainLink oracle value and multiplies it
 * with the corresponding DAI amount of 1E18 sDAI.
 * Can be deployed on any chain with sDAI contract
 * and chainLink priceFeed for DAI -> ETH.
 */

import "./ISDai.sol";
import "./IPriceFeed.sol";

contract SDAIOracle {

    constructor(
        ISDai _sDaiToken,
        IPriceFeed _IPriceFeedDAI
    )
    {
        SDAI_TOKEN = _sDaiToken;
        DAI_FEED = _IPriceFeedDAI;

        DAI_PRICE_DECIMALS = DAI_FEED.decimals();
        POW_DAI_PRICE_DECIMALS = 10 ** DAI_PRICE_DECIMALS;
    }

    // ---- Interfaces ----

    // sDAI interface
    ISDai public immutable SDAI_TOKEN;

    // priceFeed for DAI in ETH
    IPriceFeed public immutable DAI_FEED;

    // -- Immutable values --
    uint8 public immutable DAI_PRICE_DECIMALS;
    uint256 public immutable POW_DAI_PRICE_DECIMALS;

    // -- Constant values --
    uint8 internal constant FEED_DECIMALS = 18;

    // Precision factor for computations.
    uint256 internal constant PRECISION_FACTOR_E18 = 1E18;

    /**
     * @dev Read function returning latest ETH value for sDAI.
     * Uses answer from DAI chainLink pricefeed and combines it with
     * the result from {convertToAssets} for one token of sDAI.
     */
    function latestAnswer()
        public
        view
        returns (uint256)
    {
        uint256 ratioDaiToSDai = SDAI_TOKEN.convertToAssets(
            PRECISION_FACTOR_E18
        );

        (
            ,
            int256 answer,
            ,
            ,
        ) = DAI_FEED.latestRoundData();

        return ratioDaiToSDai
            * uint256(answer)
            / POW_DAI_PRICE_DECIMALS;
    }

    /**
     * @dev Returns priceFeed decimals.
     */
    function decimals()
        external
        pure
        returns (uint8)
    {
        return FEED_DECIMALS;
    }

    /**
     * @dev Read function returning the round data from
     * DAI. Needed for calibrating the priceFeed in
     * the oracleHub. (see WISE oracleHub and heartbeat)
     */
    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        (
            roundId,
            answer,
            startedAt,
            updatedAt,
            answeredInRound

        ) = DAI_FEED.getRoundData(
            _roundId
        );
    }

    /**
     * @dev Read function returning the latest round data
     * from DAI plus the latest ETH value for sDAI.
     * Needed for calibrating the pricefeed in
     * the oracleHub. (see WISE oracleHub and heartbeat)
     */
    function latestRoundData()
        public
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        answer = int256(
            latestAnswer()
        );

        (
            roundId,
            ,
            startedAt,
            updatedAt,
            answeredInRound
        ) = DAI_FEED.latestRoundData();
    }

    /**
     * @dev Read function returning the phaseId from
     * DAI. Needed for calibrating the pricefeed in
     * the oracleHub. (see WISE oracleHub and heartbeat)
     */
    function phaseId()
        external
        view
        returns (uint16)
    {
        return DAI_FEED.phaseId();
    }
}
