// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// imported contracts and libraries
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./FixedPointMathLib.sol";

// Interfaces
import "./IAggregatorV3.sol";

// errors
import "./errors.sol";

/**
 * @title   DoubleAggregator
 * @author  dsshap
 * @dev     Reports the of a token using two currency pair aggregators
 */
contract DoubleAggregator is OwnableUpgradeable, UUPSUpgradeable {
    /// @dev round data
    struct RoundData {
        int256 answer;
        uint32 updatedAt;
    }

    /*///////////////////////////////////////////////////////////////
                         Constants & Immutables
    //////////////////////////////////////////////////////////////*/

    /// @dev the primary currency pair aggregator for reporting price
    IAggregatorV3 public immutable primaryAggregator;

    /// @dev the secondary currency pair aggregator for reporting price
    IAggregatorV3 public immutable secondaryAggregator;

    /// @dev the decimal for primary aggregator
    uint8 private immutable primaryDecimals;

    /// @dev the decimal for this secondary aggregator
    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                         State Variables V1
    //////////////////////////////////////////////////////////////*/

    /// @dev desc of the pair, usually against USD
    string public description;

    /// @dev assetId => asset address
    mapping(uint80 => RoundData) private rounds;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event PriceReported(uint80 roundId, uint256 price, uint256 updatedAt);

    /*///////////////////////////////////////////////////////////////
                Constructor for implementation Contract
    //////////////////////////////////////////////////////////////*/

    constructor(address _primaryAggregator, address _secondaryAggregator) initializer {
        if (_primaryAggregator == address(0)) revert();
        if (_secondaryAggregator == address(0)) revert();

        primaryAggregator = IAggregatorV3(_primaryAggregator);
        secondaryAggregator = IAggregatorV3(_secondaryAggregator);

        primaryDecimals = primaryAggregator.decimals();
        decimals = secondaryAggregator.decimals();
    }

    /*///////////////////////////////////////////////////////////////
                            Initializer
    //////////////////////////////////////////////////////////////*/

    function initialize(address _owner, string memory _description) external initializer {
        // solhint-disable-next-line reason-string
        if (_owner == address(0)) revert();

        _transferOwnership(_owner);

        description = _description;
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
        (roundId, price, updatedAt) = getPrice(primaryAggregator.latestRound(), secondaryAggregator.latestRound());

        return (roundId, int256(price), updatedAt, updatedAt, roundId);
    }

    /**
     * @notice converts the price from the primary aggregator to the secondary aggregator
     * @param _primaryRoundId is the roundId of the primary aggregator
     * @param _secondaryRoundId is the roundId of the secondary aggregator
     * @return roundId of the new round data
     */
    function getPrice(uint256 _primaryRoundId, uint256 _secondaryRoundId)
        public
        view
        returns (uint80 roundId, uint256 price, uint256 updatedAt)
    {
        int256 primaryAnswer;

        (roundId, primaryAnswer,, updatedAt,) = primaryAggregator.getRoundData(uint80(_primaryRoundId));
        (, int256 secondaryAnswer,,,) = secondaryAggregator.getRoundData(uint80(_secondaryRoundId));

        price = FixedPointMathLib.mulDivDown(uint256(primaryAnswer), uint256(secondaryAnswer), 10 ** primaryDecimals);
    }

    /**
     * @notice stores the price
     * @param _primaryRoundId is the roundId of the primary aggregator
     * @param _secondaryRoundId is the roundId of the secondary aggregator
     * @return roundId of the new round data
     */
    function reportPrice(uint256 _primaryRoundId, uint256 _secondaryRoundId) public returns (uint80 roundId) {
        uint256 price;
        uint256 updatedAt;

        (roundId, price, updatedAt) = getPrice(_primaryRoundId, _secondaryRoundId);

        RoundData memory round = rounds[roundId];
        if (round.answer != 0) revert RoundDataReported();

        rounds[roundId] = RoundData(int256(price), uint32(updatedAt));

        emit PriceReported(roundId, price, updatedAt);
    }

    /**
     * @notice reports the spot price
     * @return roundId of the new round data
     */
    function reportSpot() external returns (uint80 roundId) {
        return reportPrice(primaryAggregator.latestRound(), secondaryAggregator.latestRound());
    }
}
