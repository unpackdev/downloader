//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ISheeshaRetroLPVault {
    function sheesha() external view returns (address);
    function userInfo(uint256 id, address user) external view returns (uint256, uint256, uint256, bool);
    function stake(uint256) external;
}