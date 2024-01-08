// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
pragma abicoder v2;

interface IRiverBoxRandom {
    function generateSignature(uint256 salt) external view returns (uint256);

    function setCaller(address riverBox) external;
}
