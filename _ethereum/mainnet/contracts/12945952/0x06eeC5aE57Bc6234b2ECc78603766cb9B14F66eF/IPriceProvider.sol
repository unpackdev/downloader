// contracts/SimpleToken.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IPriceProvider {
    // pair - uniswap address
    // base - erc20 contract as base currency
    // return price with 18 decimals precision
    function getPairPrice(address pair, address base)
        external
        view
        returns (uint256);
}