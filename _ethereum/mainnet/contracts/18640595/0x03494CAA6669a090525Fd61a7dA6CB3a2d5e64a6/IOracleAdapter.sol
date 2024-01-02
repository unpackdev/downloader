// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IOracleAdapter {
    function getSinglePrice(
        address asset,
        uint40 timestamp
    ) external view returns (uint128);

    function getPrice(
        address baseAsset,
        address quoteAsset,
        uint40 timestamp
    ) external view returns (uint128);
}
