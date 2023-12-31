// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./PriceStorage.sol";

interface IPriceTemplate {
    function getCanvasNextPrice(
        uint256 startRound,
        uint256 currentRound,
        uint256 priceFactor,
        uint256 daoFloorPrice,
        PriceStorage.MintInfo memory maxPrice,
        PriceStorage.MintInfo memory mintInfo
    )
        external
        view
        returns (uint256);

    function updateCanvasPrice(
        bytes32 daoId,
        bytes32 canvasId,
        uint256 currentRound,
        uint256 price,
        uint256 priceMultiplierInBps
    )
        external
        payable;
}
