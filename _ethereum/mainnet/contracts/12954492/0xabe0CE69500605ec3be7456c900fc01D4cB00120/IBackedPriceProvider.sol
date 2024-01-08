// contracts/SimpleToken.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

interface IBackedPriceProvider {
    function getPrice(address base)
        external
        view
        returns (uint256);
}