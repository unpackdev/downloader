// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.12;


interface IAdapter {
    function getBorrowIndex(address underlier) external view returns (uint256);
    function getBorrowRate(address underlier) external view returns (uint256);
}