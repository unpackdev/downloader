// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

interface IBondingCurve {
    function calculateInitializationReturn(uint256 _price, uint256 _reserveRatio, uint256 _slopeInit)
        external
        view
        returns (uint256);

    function calculatePurchaseReturn(
        uint256 _supply,
        uint256 _poolBalance,
        uint256 _reserveRatio,
        uint256 _price
    ) external returns (uint256);
    
    function calculateSaleReturn(
        uint256 _supply,
        uint256 _poolBalance,
        uint256 _reserveRatio,
        uint256 _tokens
    ) external returns (uint256);
}