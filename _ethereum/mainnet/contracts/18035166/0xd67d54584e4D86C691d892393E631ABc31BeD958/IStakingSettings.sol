// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IStakingSettings Settings governing a staking config for a marketplace.
 */
interface IStakingSettings {
    /**
     * @dev Get the staking percentage.
     * @return uint8 wei staking fee percentage.
     */
    function getStakingFeePercentage() external view returns (uint8);

    /**
     * @dev Utility function for calculating the staking fee for given amount of wei.
     * @param _amount uint256 wei amount.
     * @return uint256 wei fee.
     */
    function calculateStakingFee(uint256 _amount)
        external
        view
        returns (uint256);

    /**
     * @dev Utility function for calculating the marketplace payout fee for given amount of wei. marketplaceFee - stakingFee
     * @param _amount uint256 wei amount.
     * @return uint256 wei fee.
     */
    function calculateMarketplacePayoutFee(uint256 _amount)
        external
        view
        returns (uint256);
}
