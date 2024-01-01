// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// imported contracts and libraries
import "./FixedPointMathLib.sol";
import "./Ownable.sol";

// Interfaces
import "./IERC20.sol";

// errors
import "./errors.sol";

/**
 * @title   GenericAggregator
 * @author  dsshap
 * @dev     Reports the balance of Generic Token, should only be used in testnets
 */
contract GenericAggregator is Ownable {
    /// @dev round data Ownable
    struct RoundData {
        int256 answer;
        uint32 updatedAt;
    }

    /*///////////////////////////////////////////////////////////////
                         State Variables V1
    //////////////////////////////////////////////////////////////*/

    /// @dev the erc20 token that is being reported on
    IERC20 public immutable token;

    /// @dev the decimal for the underlying
    uint8 public immutable decimals;

    /// @dev desc of the pair, usually against USD
    string public description;

    /// @dev last id used to represent round data
    uint80 private lastRoundId;

    /// @dev assetId => asset address
    mapping(uint80 => RoundData) private rounds;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event BalanceReported(uint80 roundId, uint256 price, uint256 updatedAt);

    /*///////////////////////////////////////////////////////////////
                Constructor for implementation Contract
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner, address _token, uint8 _decimals, string memory _description) {
        if (_owner == address(0)) revert();

        _transferOwnership(_owner);

        token = IERC20(_token);
        decimals = _decimals;
        description = _description;
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
        uint80 _roundId = lastRoundId;
        RoundData memory round = rounds[_roundId];

        return (_roundId, round.answer, round.updatedAt, round.updatedAt, _roundId);
    }

    /**
     * @notice reports the balance of funds
     * @dev only callable by the owner
     * @param _answer is the answer
     * @param _updatedAt is the timestamp
     * @return roundId of the new round data
     */
    function reportBalance(uint256 _answer, uint256 _updatedAt) external returns (uint80 roundId) {
        _checkOwner();

        roundId = lastRoundId;
        lastRoundId = roundId += 1;

        rounds[roundId] = RoundData(int56(int256(_answer)), uint32(_updatedAt));

        emit BalanceReported(roundId, _answer, _updatedAt);
    }
}
