// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ITWBalance
{
    struct TWItem
    {
        // the block timestamp
        uint48  timestamp;        
        // the amount accumulator, i.e. amount * time elapsed
        uint208 amountTW;
    }

    /// @notice Returns the time weight (TW) amount of tokens in existence.
    function totalSupplyTW() external view returns (TWItem memory);

    /// @notice Calculates the average aamount of tokens in existence from the specified TW period
    function totalSupplyAvg(TWItem memory itemStart) view external returns (uint256);

    /// @notice Returns the time weight (TW) balance of a token
    /// @param user The account for which to look up the number of tokens it has, i.e. its balance
    /// @return The number of tokens held by the account
    function balanceOfTW(address user) external view returns (TWItem memory);
    
    /// @notice Calculates the average address balance from the specified TW period
    function balanceOfAvg(address user, TWItem memory itemStart) view external returns (uint256);

}
