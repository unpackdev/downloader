// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IConvexWithdraw{
    function withdrawAndUnwrap(uint256, bool) external;
    function balanceOf(address account) external view returns (uint256);
    function earned(address account) external view returns (uint256);
    function getReward() external;
}