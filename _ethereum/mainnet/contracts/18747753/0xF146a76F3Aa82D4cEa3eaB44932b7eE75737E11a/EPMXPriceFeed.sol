// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./IAccessControl.sol";
import "./IERC165.sol";
import "./AggregatorV2V3Interface.sol";

import "./Errors.sol";

import "./Constants.sol";
import "./IEPMXPriceFeed.sol";

contract EPMXPriceFeed is IEPMXPriceFeed, AggregatorV2V3Interface {
    uint80 internal constant MAX_UINT80_HEX = type(uint80).max;

    struct RoundData {
        uint80 roundId;
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }

    address public immutable registry;
    uint8 public override decimals = 8; // USD decimals
    uint80 private _currentRound;
    RoundData private _latestRoundData;
    mapping(uint80 => RoundData) private _answers;

    /**
     * @dev Modifier that checks if the caller has a specific role.
     * @param _role The role identifier to check.
     */
    modifier onlyRole(bytes32 _role) {
        _require(IAccessControl(registry).hasRole(_role, msg.sender), Errors.FORBIDDEN.selector);
        _;
    }

    constructor(address _registry) {
        _require(
            IERC165(_registry).supportsInterface(type(IAccessControl).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        registry = _registry;
    }

    /**
     * @notice Retrieves the latest answer from the oracle.
     * @return The latest answer, with a precision of 8 decimal (USD decimals).
     */
    function latestAnswer() external view override returns (int256) {
        return _latestRoundData.answer;
    }

    /**
     * @notice Returns the latest round data.
     * @return roundId The ID of the latest round.
     * @return answer The answer provided in the latest round.
     * @return startedAt The timestamp when the latest round started.
     * @return updatedAt The timestamp when the latest round was updated.
     * @return answeredInRound The round in which the latest answer was provided.
     */
    function latestRoundData() external view override returns (uint80, int256, uint256, uint256, uint80) {
        return (
            _latestRoundData.roundId,
            _latestRoundData.answer,
            _latestRoundData.startedAt,
            _latestRoundData.updatedAt,
            _latestRoundData.answeredInRound
        );
    }

    /**
     * @notice Retrieves the latest timestamp of the round data.
     * @return The latest timestamp of when the round was updated, in seconds (UTC).
     */
    function latestTimestamp() external view override returns (uint256) {
        return _latestRoundData.updatedAt;
    }

    /**
     * @notice Retrieves the answer for a given round ID.
     * @param roundId The round ID for which to get the answer.
     * @return The answer previously set with setAnswer().
     */
    function getAnswer(uint256 roundId) external view override returns (int256) {
        if (roundId > MAX_UINT80_HEX) {
            return 0;
        }
        return _answers[uint80(roundId)].answer;
    }

    /**
     * @notice Retrieves the timestamp of a given round ID.
     * @param roundId The round ID for which to retrieve the timestamp.
     * @return The timestamp when the round was last updated.
     */
    function getTimestamp(uint256 roundId) external view override returns (uint256) {
        if (roundId > MAX_UINT80_HEX) {
            return 0;
        }
        return _answers[uint80(roundId)].updatedAt;
    }

    /**
     * @notice Retrieves the latest round ID.
     * @return The latest round ID.
     */
    function latestRound() external view override returns (uint256) {
        return _latestRoundData.roundId;
    }

    /**
     * @inheritdoc IEPMXPriceFeed
     */
    function setAnswer(int256 answer) public override onlyRole(BIG_TIMELOCK_ADMIN) {
        _latestRoundData.answer = answer;
        _latestRoundData.roundId = _currentRound;
        _latestRoundData.startedAt = block.timestamp;
        _latestRoundData.updatedAt = block.timestamp;
        _latestRoundData.answeredInRound = _currentRound;
        _answers[_currentRound] = _latestRoundData;
        _currentRound++;
        emit AnswerUpdated(answer, _latestRoundData.roundId, block.timestamp);
    }

    /**
     * @notice Retrieves the data for a specific round.
     * @param _roundId The ID of the round to retrieve data for.
     * @return roundId The ID of the round.
     * @return answer The answer for the round.
     * @return startedAt The timestamp when the round started.
     * @return updatedAt The timestamp when the round was last updated.
     * @return answeredInRound The ID of the round in which the answer was computed.
     */
    function getRoundData(uint80 _roundId) public view override returns (uint80, int256, uint256, uint256, uint80) {
        RoundData memory roundData = _answers[_roundId];
        return (
            roundData.roundId,
            roundData.answer,
            roundData.startedAt,
            roundData.updatedAt,
            roundData.answeredInRound
        );
    }

    /**
     * @notice Returns the description of the contract.
     * @return The description string "EPMX / USD".
     */
    function description() public pure override returns (string memory) {
        return "EPMX / USD";
    }

    /**
     * @notice This function provides the version number of the contract.
     */
    function version() public pure override returns (uint256) {
        return 0;
    }
}
