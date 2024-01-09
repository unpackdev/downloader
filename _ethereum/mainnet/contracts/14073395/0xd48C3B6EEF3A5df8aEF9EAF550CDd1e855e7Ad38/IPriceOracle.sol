// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IPriceOracle {
    function refreshPrice(
        address underlying_,
        uint64 fromDate_,
        uint64 toDate_
    ) external;

    function getPrice(
        address underlying_,
        uint64 fromDate_,
        uint64 toDate_
    ) external view returns (int256);
}
