// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./ICalculations.sol";

/**
 * @title Dollet IPendleCalculations
 * @author Dollet Team
 * @notice Interface for PendleCalculations contract.
 */
interface IPendleCalculations is ICalculations {
    /**
     * @notice Retrieves information about pending rewards to compound.
     * @param _rewardData Encoded bytes with information about the reward tokens.
     * @return _rewardAmounts Rewards amounts representing pending rewards.
     * @return _rewardTokens Addresses of the reward tokens.
     * @return _enoughRewards List indicating if the reward token is enough to compound.
     * @return _atLeastOne Indicates if there is at least one reward to compound.
     */
    function getPendingToCompound(bytes memory _rewardData)
        external
        view
        returns (
            uint256[] memory _rewardAmounts,
            address[] memory _rewardTokens,
            bool[] memory _enoughRewards,
            bool _atLeastOne
        );

    /**
     * @notice Given an amount of target asset, this function calculates the equivalent in want asset.
     * @param _amountTarget The amount of target tokens to use in calculations.
     * @return The equivalent amount in want asset.
     */
    function convertTargetToWant(uint256 _amountTarget) external view returns (uint256);

    /**
     * @notice Given an amount of want asset, this function calculates the equivalent in target asset.
     * @param _amountWant The amount of want tokens to use in calculations.
     * @return The equivalent amount in target asset.
     */
    function convertWantToTarget(uint256 _amountWant) external view returns (uint256);
}
