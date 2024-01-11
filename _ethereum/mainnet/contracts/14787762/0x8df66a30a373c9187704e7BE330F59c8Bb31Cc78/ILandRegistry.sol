// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ILandRegistry {
    function transferFrom(
        address from,
        address to,
        uint256 assetId
    ) external;

    function setUpdateOperator(uint256 assetId, address operator) external;
}
