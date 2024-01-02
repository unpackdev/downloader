// SPDX-License-Identifier: BUSL-1.1

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
