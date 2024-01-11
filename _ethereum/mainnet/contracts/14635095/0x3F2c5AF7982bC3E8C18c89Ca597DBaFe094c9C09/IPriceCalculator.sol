// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IPriceCalculator {
    function calculatePrice(
        uint256 startingPrice,
        uint256 listedOn,
        uint256 time
    ) external pure returns (uint256);

    function calculateCurrentPrice(
        uint256 startingPrice,
        uint256 listedOn
    ) external view returns (uint256);

    function isPriceAllowed(
        uint256 startingPrice
    ) external pure returns (bool);
}