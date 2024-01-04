//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

/// RewardsPool as seen by others
interface IRewardsPool {
    /// Supply of staking token
    function totalSupply() external view returns (uint256);

    /// Balance of staking token
    function balanceOf(address account) external view returns (uint256);
}
