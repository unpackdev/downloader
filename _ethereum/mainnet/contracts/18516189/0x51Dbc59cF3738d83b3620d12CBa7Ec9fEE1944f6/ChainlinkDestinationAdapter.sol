// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import "./DecimalLib.sol";
import "./IAggregatorV3.sol";
import "./DiamondRootOevShare.sol";

/**
 * @title ChainlinkDestinationAdapter contract to expose OEVShare data via the standard Chainlink Aggregator interface.
 */

abstract contract ChainlinkDestinationAdapter is DiamondRootOevShare, IAggregatorV3 {
    uint8 public immutable override decimals;

    event DecimalsSet(uint8 indexed decimals);

    constructor(uint8 _decimals) {
        decimals = _decimals;

        emit DecimalsSet(_decimals);
    }

    /**
     * @notice Returns the latest data from the source.
     * @return answer The latest answer in the configured number of decimals.
     */
    function latestAnswer() public view override returns (int256) {
        (int256 answer,) = internalLatestData();
        return DecimalLib.convertDecimals(answer, 18, decimals);
    }

    /**
     * @notice Returns when the latest answer was updated.
     * @return timestamp The timestamp of the latest answer.
     */
    function latestTimestamp() public view override returns (uint256) {
        (, uint256 timestamp) = internalLatestData();
        return timestamp;
    }

    /**
     * @notice Returns an approximate form of the latest Round data. This does not implement the notion of "roundId" that
     * the normal chainlink aggregator does and returns hardcoded values for those fields.
     * @return roundId The roundId of the latest answer, hardcoded to 1.
     * @return answer The latest answer in the configured number of decimals.
     * @return startedAt The timestamp when the value was updated.
     * @return updatedAt The timestamp when the value was updated.
     * @return answeredInRound The roundId of the round in which the answer was computed, hardcoded to 1.
     */
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        (int256 answer, uint256 updatedAt) = internalLatestData();
        return (1, DecimalLib.convertDecimals(answer, 18, decimals), updatedAt, updatedAt, 1);
    }
}
