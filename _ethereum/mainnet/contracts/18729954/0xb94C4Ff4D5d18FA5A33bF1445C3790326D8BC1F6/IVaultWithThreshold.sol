// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.17;

interface IVaultWithThreshold {
    event ThresholdSet(uint256 threshold);

    function threshold() external view returns (uint256);

    function setThreshold(uint256 threshold) external;
}
