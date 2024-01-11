//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ISheeshaRetroSHVault {
    function sheesha() external view returns (address);
    function userInfo(uint256 id, address user) external view returns (uint256, uint256);
    function stake(uint256) external;
}