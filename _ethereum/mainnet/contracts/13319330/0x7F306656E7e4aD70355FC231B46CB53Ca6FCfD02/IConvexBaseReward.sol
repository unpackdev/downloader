// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IConvexBaseReward {
    function getReward() external returns(bool);
    function withdrawAndUnwrap(uint256 amount, bool claim) external returns(bool);
    function balanceOf(address account) external view returns (uint256);
}