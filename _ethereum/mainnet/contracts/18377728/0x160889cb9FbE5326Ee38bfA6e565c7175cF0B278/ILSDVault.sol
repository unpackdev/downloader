// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface ILSDVault {
    function stakedETHperunshETH() external view returns (uint256);
    function exit(uint256 amount) external;
}
