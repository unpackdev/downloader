// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface IPriceOracleStorage {
    function registry() external view returns (address);

    function eth() external view returns (address);

    function gasPriceFeed() external view returns (address);

    function pairPriceDrops(address, address) external view returns (uint256);
}
