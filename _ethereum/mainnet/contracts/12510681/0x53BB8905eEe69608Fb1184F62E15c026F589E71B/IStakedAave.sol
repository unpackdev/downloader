// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "./IERC20.sol";

/**
 * @dev This interface allows the auction contract to interact with staked AAVE.
 */
interface IStakedAave is IERC20 {
    function stake(address onBehalfOf, uint256 amount) external;

    function claimRewards(address to, uint256 amount) external;

    function getTotalRewardsBalance(address staker)
        external
        view
        returns (uint256);
}
