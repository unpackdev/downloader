// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./Errors.sol";
import "./IAccessControl.sol";
import "./PercentageMath.sol";
import "./KIBTAggregatorInterface.sol";
import "./Roles.sol";

/**
 * @title MCAG Aggregator
 * @author MIMO Labs
 * @notice MCAGAggregator contracts serve as an oracle for the MCAGRateFeed
 */

contract KIBTAggregator is KIBTAggregatorInterface {
    using PercentageMath for uint256;

    uint256 public constant MIN_TERM = 4 weeks;

    uint8 private constant _VERSION = 1;
    uint8 private constant _DECIMALS = 8;

    IAccessControl public immutable accessController;

    uint80 private _roundId;
    uint16 private _volatilityThreshold;
    string private _description;
    int256 private _answer;
    int256 private _maxAnswer;
    uint256 private _updatedAt;

    /**
     * @dev Modifier to make a function callable only when the caller has a specific role
     * @param role The role required to call the function
     */
    modifier onlyRole(bytes32 role) {
        if (!accessController.hasRole(role, msg.sender)) {
            revert Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE(msg.sender, role);
        }
        _;
    }

    /**
     * @param description_ Description of the oracle - for example "USK/USD"
     * @param maxAnswer_ Maximum sensible answer the contract should accept during transmission
     * @param _accessController MCAG AccessController
     */
    constructor(
        string memory description_,
        int256 maxAnswer_,
        IAccessControl _accessController,
        int256 answer,
        uint16 volatilityThreshold
    ) {
        if (address(_accessController) == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }
        if (volatilityThreshold == 0) {
            revert Errors.INVALID_VOLATILITY_THRESHOLD();
        }
        if (answer > maxAnswer_) {
            revert Errors.TRANSMITTED_ANSWER_TOO_HIGH(answer, maxAnswer_);
        }

        accessController = _accessController;
        _volatilityThreshold = volatilityThreshold;
        _description = description_;
        _answer = answer;
        _maxAnswer = maxAnswer_;
        _updatedAt = block.timestamp;

        emit AccessControllerSet(address(_accessController));
        emit AnswerTransmitted(msg.sender, 0, answer);
        emit MaxAnswerSet(0, maxAnswer_);
        emit VolatilityThresholdSet(0, volatilityThreshold);
    }

    /**
     * @notice Transmits a new price to the aggreator and updates the answer, round id and updated at
     * @dev Can only be called by a registered transmitter
     * @param answer New KIBT price
     */
    function transmit(int256 answer) external onlyRole(Roles.MCAG_TRANSMITTER_ROLE) {
        if (answer > _maxAnswer) {
            revert Errors.TRANSMITTED_ANSWER_TOO_HIGH(answer, _maxAnswer);
        }
        if (answer < 0) {
            revert Errors.TRANSMITTED_ANSWER_TOO_LOW(answer, 0);
        }

        int256 answer_ = _answer;
        uint256 oldAnswer = uint256(answer_);
        uint256 newAnswer = uint256(answer);

        if (newAnswer > oldAnswer) {
            if (newAnswer > oldAnswer.percentMul(PercentageMath.PERCENTAGE_FACTOR + _volatilityThreshold)) {
                revert Errors.ANSWER_VARIATION_TOO_HIGH();
            }
        } else {
            if (newAnswer < oldAnswer.percentMul(PercentageMath.PERCENTAGE_FACTOR - _volatilityThreshold)) {
                revert Errors.ANSWER_VARIATION_TOO_HIGH();
            }
        }

        ++_roundId;
        _updatedAt = block.timestamp;
        _answer = answer;

        emit AnswerTransmitted(msg.sender, _roundId, answer);
    }

    /**
     * @notice Sets a new max answer
     * @dev Can only be called by MCAG Manager
     * @param newMaxAnswer New maximum sensible answer the contract should accept
     */
    function setMaxAnswer(int256 newMaxAnswer) external onlyRole(Roles.MCAG_MANAGER_ROLE) {
        if (newMaxAnswer < 0) {
            revert Errors.CANNOT_SET_NEGATIVE_MAX_ANSWER();
        }
        emit MaxAnswerSet(_maxAnswer, newMaxAnswer);
        _maxAnswer = newMaxAnswer;
    }

    /**
     * @notice Sets a new volatility threshold
     * @dev Can only be called by MCAG Manager
     * @param newVolatilityThreshold New maximum absolute value change of the answer between two consecutive rounds
     */
    function setVolatilityThreshold(uint16 newVolatilityThreshold) external onlyRole(Roles.MCAG_MANAGER_ROLE) {
        if (newVolatilityThreshold == 0 || newVolatilityThreshold > PercentageMath.PERCENTAGE_FACTOR) {
            revert Errors.INVALID_VOLATILITY_THRESHOLD();
        }
        emit VolatilityThresholdSet(_volatilityThreshold, newVolatilityThreshold);
        _volatilityThreshold = newVolatilityThreshold;
    }

    /**
     * @notice Returns the latest answer as well as the timestamp of the last update
     * @dev This function is compatible with the Chainlink Oracle specification
     * @return roundId The round ID
     * @return answer The answer in _DECIMALS precision
     * @return startedAt Timestamp of when the round started
     * @return updatedAt Timestamp of when the round was updated
     * @return answeredInRound The round ID of the round in which the answer was computed
     */
    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        roundId = _roundId;
        answer = _answer;
        startedAt = _updatedAt;
        updatedAt = _updatedAt;
        answeredInRound = _roundId;
    }

    /**
     * @return Description of the oracle - for example "USK/USD".
     */
    function description() external view returns (string memory) {
        return _description;
    }

    /**
     * @return Maximum sensible answer the contract should accept.
     */
    function getMaxAnswer() external view returns (int256) {
        return _maxAnswer;
    }

    /**
     * @return Maximum absolute value change of the answer between two consecutive rounds.
     */
    function getVolatilityThreshold() external view returns (uint256) {
        return _volatilityThreshold;
    }

    /**
     * @return Number of decimals used to get its user representation.
     */
    function decimals() external pure returns (uint8) {
        return _DECIMALS;
    }

    /**
     * @return Contract version.
     */
    function version() external pure returns (uint8) {
        return _VERSION;
    }
}
