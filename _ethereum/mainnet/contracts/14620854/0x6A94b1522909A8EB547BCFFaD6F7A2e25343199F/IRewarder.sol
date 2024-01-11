// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "./IERC20.sol";

interface IRewarder {
    function onIOSTReward(uint256 pid, address user, address recipient, uint256 iostAmount, uint256 newLpAmount) external;
    function pendingTokens(uint256 pid, address user, uint256 iostAmount) external view returns (IERC20[] memory, uint256[] memory);
}