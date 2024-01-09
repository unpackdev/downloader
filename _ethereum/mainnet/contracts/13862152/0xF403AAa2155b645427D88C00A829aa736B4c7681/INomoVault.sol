// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface INomoVault {
    function nftSaleCallback(
        uint256[] memory tokensIds,
        uint256[] memory prices
    ) external;
}