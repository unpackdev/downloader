// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
import "./IERC20.sol";
import "./SafeERC20.sol";

interface IRewarder {
    using SafeERC20 for IERC20;
    function onReward(uint256 pid, address user, address recipient, uint256 sushiAmount, uint256 newLpAmount) external;
    function pendingTokens(uint256 pid, address user, uint256 sushiAmount) external view returns (IERC20[] memory, uint256[] memory);
}