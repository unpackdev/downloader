// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IVester {
    function vest(address user, uint256 amount) external; // called by esembr contract only. This is where esembr contract will transfer the vested embr amount to the vester.
    function claimable(address user) external view returns (uint256 /* claimable amount */, uint256 /* entry time */);
    function claim(address user) external returns (uint256); // called by esembr contract only
    function vestingTime() external view returns (uint256);
    function vestingAmount(address) external view returns (uint256);
}
