// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// imported contracts and libraries
import "./FixedPointMathLib.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";

import "./ILSETH.sol";
import "./IAggregatorV3.sol";

// errors
import "./errors.sol";

/**
 * @title   LSETHAggregator
 * @author  dsshap
 * @dev     Reports the conversion rate of LsETH
 */
contract LSETHAggregator is OwnableUpgradeable, UUPSUpgradeable {
    /// @dev round data package
    struct RoundData {
        int256 answer;
        uint256 rate;
        uint256 updatedAt;
    }

    /*///////////////////////////////////////////////////////////////
                         State Variables V1
    //////////////////////////////////////////////////////////////*/

    /// @dev the erc20 token that is being reported on
    ILSETH public immutable token;

    /// @dev the currency pair aggregator for reporting price
    IAggregatorV3 public immutable cPairAggregator;

    /// @dev the decimal for the underlying
    uint8 public immutable tokenDecimals;

    /// @dev the decimal for the currency pair aggregator
    uint8 public immutable decimals;

    /// @dev desc of the pair, usually against USD
    string public description;

    uint256 public maxDelay;

    /// @dev assetId => asset address
    mapping(uint80 => RoundData) private rounds;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event PriceAndRateReported(uint80 roundId, uint256 price, uint256 rate, uint256 updatedAt);

    event PriceAndRateForced(uint80 roundId, uint256 price, uint256 rate, uint256 updatedAt);

    /*///////////////////////////////////////////////////////////////
                Constructor for implementation Contract
    //////////////////////////////////////////////////////////////*/

    constructor(address _token, address _cPairAggregator) initializer {
        token = ILSETH(_token);
        tokenDecimals = token.decimals();

        cPairAggregator = IAggregatorV3(_cPairAggregator);
        decimals = cPairAggregator.decimals();
    }

    /*///////////////////////////////////////////////////////////////
                            Initializer
    //////////////////////////////////////////////////////////////*/

    function initialize(address _owner, string memory _description, uint256 _maxDelay) external initializer {
        // solhint-disable-next-line reason-string
        if (_owner == address(0)) revert();

        _transferOwnership(_owner);

        description = _description;
        maxDelay = _maxDelay;
    }

    /*///////////////////////////////////////////////////////////////
                    Override Upgrade Permission
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Upgradable by the owner.
     *
     */

    function _authorizeUpgrade(address /*newImplementation*/ ) internal virtual override {
        _checkOwner();
    }

    /*///////////////////////////////////////////////////////////////
                        External Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev admin function to update max delay
     */
    function setMaxDelay(uint256 _maxDelay) external {
        _checkOwner();

        maxDelay = _maxDelay;
    }

    /**
     * @notice get data about a round
     * @return roundId is the round ID for which data was retrieved
     * @return answer is the answer for the given round
     * @return startedAt is always equal to updatedAt
     * @return updatedAt is the timestamp when the round last was updated (i.e. answer was last computed)
     * @return answeredInRound is always equal to roundId
     */
    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        RoundData memory round = rounds[_roundId];

        return (_roundId, round.answer, round.updatedAt, round.updatedAt, _roundId);
    }

    /**
     * @notice get data about the latest round
     * @return roundId is the round ID for which data was retrieved
     * @return answer is the answer for the given round
     * @return startedAt is always equal to updatedAt
     * @return updatedAt is the timestamp when the round last was updated (i.e. answer was last computed)
     * @return answeredInRound is always equal to roundId
     */
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        uint256 price;

        (roundId, price,, updatedAt) = _getSpot();

        return (roundId, int256(price), updatedAt, updatedAt, roundId);
    }

    /**
     * @notice get conversion rate data about a round
     * @return roundId is the round ID for which data was retrieved
     * @return answer is the price for the given round
     * @return rate the total conversion rate between LsETH and USD
     * @return updatedAt is the timestamp when the round last was updated (i.e. answer was last computed)
     */
    function getRoundDetails(uint80 _roundId)
        public
        view
        returns (uint80 roundId, int256 answer, uint256 rate, uint256 updatedAt)
    {
        RoundData memory round = rounds[_roundId];

        return (_roundId, round.answer, round.rate, round.updatedAt);
    }

    /**
     * @notice get conversion from the latest round
     * @return roundId is the round ID for which data was retrieved
     * @return answer is the price for the given round
     * @return rate the total conversion rate between LsETH and USD
     * @return updatedAt is the timestamp when the round last was updated (i.e. answer was last computed)
     */
    function latestRoundDetails() external view returns (uint80 roundId, int256 answer, uint256 rate, uint256 updatedAt) {
        uint256 price;

        (roundId, price, rate, updatedAt) = _getSpot();

        return (roundId, int256(price), rate, updatedAt);
    }

    /**
     * @notice reports the balance of money market funds
     * @return roundId of the new round data
     */
    function recordPriceAndRate() external returns (uint80 roundId) {
        uint256 price;
        uint256 rate;
        uint256 updatedAt;

        (roundId, price, rate, updatedAt) = _getSpot();

        RoundData memory round = rounds[roundId];
        if (round.answer != 0) revert RoundDataReported();

        rounds[roundId] = RoundData(int256(price), rate, updatedAt);

        emit PriceAndRateReported(roundId, price, rate, updatedAt);
    }

    function forceRoundData(uint80 _roundId, uint256 _price, uint256 _rate, uint256 _updatedAt) external {
        _checkOwner();

        RoundData memory round = rounds[_roundId];
        if (round.answer != 0) revert RoundDataReported();

        rounds[_roundId] = RoundData(int256(_price), _rate, _updatedAt);

        emit PriceAndRateForced(_roundId, _price, _rate, _updatedAt);
    }

    function _getSpot() internal view returns (uint80 roundId, uint256 price, uint256 rate, uint256 updatedAt) {
        int256 answer;

        (roundId, answer,, updatedAt,) = cPairAggregator.latestRoundData();

        if (block.timestamp - updatedAt > maxDelay) revert StaleAnswer();

        rate = FixedPointMathLib.mulDivDown(token.totalUnderlyingSupply(), 10 ** tokenDecimals, token.totalSupply());
        price = FixedPointMathLib.mulDivDown(uint256(answer), rate, 10 ** tokenDecimals);
    }
}
