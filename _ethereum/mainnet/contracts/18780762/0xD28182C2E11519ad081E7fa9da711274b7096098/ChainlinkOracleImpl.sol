// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "./AddressUtils.sol";
import "./AggregatorV3Interface.sol";
import "./LibQuotes.sol";
import "./LibQuotes.sol";
import "./TokenUtils.sol";
import "./FixedPointMathLib.sol";
import "./OracleImpl.sol";
import "./ChainlinkPairDetails.sol";
import "./ChainlinkPath.sol";

/// @title Chainlink Oracle Implementation
/// @author 0xSplits
/// @notice A clone-implementation of an oracle using Chainlink
/// @dev This contract uses token = address(0) to refer to ETH.
contract ChainlinkOracleImpl is OracleImpl {
    /// -----------------------------------------------------------------------
    /// libraries
    /// -----------------------------------------------------------------------

    using AddressUtils for address;
    using TokenUtils for address;
    using ChainlinkPairDetails for mapping(address => mapping(address => PairDetail));
    using FixedPointMathLib for uint256;
    using ChainlinkPath for bytes;

    /// -----------------------------------------------------------------------
    /// errors
    /// -----------------------------------------------------------------------

    error InvalidPair_FeedNotSet(QuotePair qp);
    error StalePrice(AggregatorV3Interface feed, uint256 timestamp);
    error NegativePrice(AggregatorV3Interface feed, int256 price);
    error ZeroPrice();

    /// -----------------------------------------------------------------------
    /// structs
    /// -----------------------------------------------------------------------

    struct InitParams {
        /// @notice owner of the contract
        address owner;
        /// @notice paused state of the contract
        bool paused;
        /// @notice initial pair details
        SetPairDetailParams[] pairDetails;
    }

    struct SetPairDetailParams {
        QuotePair quotePair;
        PairDetail pairDetail;
    }

    struct PairDetail {
        /// @notice packed encoded feed[]
        bytes path;
        /// @notice if true, the price calculated by the path will be inverted
        bool inverted;
    }

    struct Feed {
        AggregatorV3Interface feed;
        uint24 staleAfter;
        /// @dev decimals should be same as feed.decimals()
        uint8 decimals;
        /// @dev operation to perform on the price with the previous price in the path
        bool mul;
    }

    /// -----------------------------------------------------------------------
    /// events
    /// -----------------------------------------------------------------------

    event SetPairDetails(SetPairDetailParams[] params);

    /// -----------------------------------------------------------------------
    /// storage
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// storage - constants & immutables
    /// -----------------------------------------------------------------------

    address public immutable weth9;
    address public immutable chainlinkOracleFactory;
    uint256 internal constant WAD = 1e18;

    /// -----------------------------------------------------------------------
    /// storage - mutables
    /// -----------------------------------------------------------------------

    /// @notice The pair details
    mapping(address => mapping(address => PairDetail)) internal $_pairDetails;

    /// -----------------------------------------------------------------------
    /// constructor & initializer
    /// -----------------------------------------------------------------------

    /**
     * @notice constructor
     * @param weth9_ The WETH9 contract address
     */
    constructor(address weth9_) {
        weth9 = weth9_;
        chainlinkOracleFactory = msg.sender;
    }

    /**
     * @notice Initialize the contract
     * @param params_ The init params
     * @dev There is no check to prevent this function from being called more than once if deployed without a factory,
     *      It is recommended to use a factory to deploy this contract.
     */
    function initializer(InitParams calldata params_) external {
        // only chainlinkOracleFactory may call `initializer`
        if (msg.sender != chainlinkOracleFactory) revert Unauthorized();

        __initOwnable(params_.owner);
        $paused = params_.paused;

        _setPairDetails(params_.pairDetails);
    }

    /// -----------------------------------------------------------------------
    /// functions
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// functions - public & external - onlyOwner
    /// -----------------------------------------------------------------------

    /**
     * @notice Set pair details
     * @param params_ The set pair details params consisting of quote pair and pair detail
     */
    function setPairDetails(SetPairDetailParams[] calldata params_) external onlyOwner {
        _setPairDetails(params_);
        emit SetPairDetails(params_);
    }

    /// -----------------------------------------------------------------------
    /// functions - public & external - view
    /// -----------------------------------------------------------------------

    /**
     * @notice Get pair details
     * @param quotePairs_ The quote pairs
     * @return pairDetails The pair details for the quote pairs
     */
    function getPairDetails(QuotePair[] calldata quotePairs_) external view returns (PairDetail[] memory pairDetails) {
        uint256 length = quotePairs_.length;
        pairDetails = new PairDetail[](length);
        for (uint256 i; i < length;) {
            pairDetails[i] = $_pairDetails._get(_convert, quotePairs_[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Get quote amounts
     * @param quoteParams_ The quote params
     * @return quoteAmounts The quote amounts
     */
    function getQuoteAmounts(QuoteParams[] calldata quoteParams_)
        public
        view
        virtual
        pausable
        returns (uint256[] memory quoteAmounts)
    {
        uint256 length = quoteParams_.length;
        quoteAmounts = new uint256[](length);
        for (uint256 i; i < length;) {
            quoteAmounts[i] = _getQuoteAmount(quoteParams_[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// -----------------------------------------------------------------------
    /// functions - private & internal
    /// -----------------------------------------------------------------------

    function _setPairDetails(SetPairDetailParams[] calldata params_) internal {
        $_pairDetails._set(_convert, params_);
    }

    /// -----------------------------------------------------------------------
    /// functions - private & internal - views
    /// -----------------------------------------------------------------------

    function _getQuoteAmount(QuoteParams calldata quoteParams_) internal view returns (uint256) {
        ConvertedQuotePair memory cqp = quoteParams_.quotePair._convert(_convert);

        if (cqp.cBase == cqp.cQuote) {
            return quoteParams_.baseAmount;
        }

        PairDetail memory pd = $_pairDetails._get(cqp);
        if (pd.path.length == 0) {
            revert InvalidPair_FeedNotSet(quoteParams_.quotePair);
        }

        Feed[] memory feeds = pd.path.getFeeds();
        uint256 feedLength = feeds.length;

        uint256 price = _getFeedAnswer(feeds[0]);
        for (uint256 i = 1; i < feedLength;) {
            uint256 answer = _getFeedAnswer(feeds[i]);
            if (feeds[i].mul) {
                price = price.mulWadDown(answer);
            } else {
                price = price.divWadDown(answer);
            }
            unchecked {
                ++i;
            }
        }
        if (pd.inverted) price = WAD.divWadDown(price);
        if (price == 0) revert ZeroPrice();
        return _convertPriceToQuoteAmount(price, quoteParams_);
    }

    function _getFeedAnswer(Feed memory feed_) internal view returns (uint256) {
        (
            , /* uint80 roundId, */
            int256 answer,
            , /* uint256 startedAt, */
            uint256 updatedAt,
            /* uint80 answeredInRound */
        ) = feed_.feed.latestRoundData();

        if (updatedAt + feed_.staleAfter < block.timestamp) {
            revert StalePrice(feed_.feed, updatedAt);
        }
        if (answer < 0) {
            revert NegativePrice(feed_.feed, answer);
        }

        if (feed_.decimals <= 18) {
            return uint256(answer) * 10 ** (18 - feed_.decimals);
        } else {
            return uint256(answer) / 10 ** (feed_.decimals - 18);
        }
    }

    function _convertPriceToQuoteAmount(uint256 price_, QuoteParams calldata quoteParams_)
        internal
        view
        returns (uint256 finalAmount)
    {
        uint8 baseDecimals = quoteParams_.quotePair.base._decimals();
        uint8 quoteDecimals = quoteParams_.quotePair.quote._decimals();

        finalAmount = price_ * quoteParams_.baseAmount;
        if (18 > quoteDecimals) {
            finalAmount = finalAmount / (10 ** (18 - quoteDecimals));
        } else if (18 < quoteDecimals) {
            finalAmount = finalAmount * (10 ** (quoteDecimals - 18));
        }
        finalAmount = finalAmount / 10 ** baseDecimals;
    }

    function _convert(address token_) internal view returns (address) {
        return token_._isETH() ? weth9 : token_;
    }
}
