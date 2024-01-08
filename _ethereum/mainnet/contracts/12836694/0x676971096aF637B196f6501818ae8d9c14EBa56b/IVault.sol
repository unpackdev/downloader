// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IVault {
    function baseAsset() external view returns (address);

    function deposit(uint256 baseAmount) external;
    function withdraw(uint256 shareAmount) external;
}