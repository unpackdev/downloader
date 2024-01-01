// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Interface for Chainlink Aggregator V3
interface AggregatorV3Interface {
    /// @notice Returns the number of decimals used by the price feed
    /// @return The number of decimals
    function decimals() external view returns (uint8);

    /// @notice Returns a description of the price feed
    /// @return The description of the price feed
    function description() external view returns (string memory);

    /// @notice Returns the version number of the price feed
    /// @return The version number
    function version() external view returns (uint256);

    /// @notice Returns the latest answer from the price feed
    /// @return The latest answer
    function latestAnswer() external view returns (int256);

    /// @notice Returns the data for the latest round of the price feed
    /// @return roundId The ID of the latest round
    /// @return answer The latest answer
    /// @return startedAt The timestamp when the latest round started
    /// @return updatedAt The timestamp when the latest round was last updated
    /// @return answeredInRound The ID of the round when the latest answer was computed
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}
