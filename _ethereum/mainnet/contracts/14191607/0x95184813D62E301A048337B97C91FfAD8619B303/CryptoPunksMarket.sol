// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface CryptoPunksMarket {
    function punkIndexToAddress(uint256) external view returns (address);
}
