// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.0;

interface IBumpMarket {
    enum StableCoins {USDC}

    function getyUSDCIssuedToReserve() external view returns (uint256 amount);

    function estimateBumpRewards(
        uint256 _totalDeposit,
        uint256 _amountForPurchase
    ) external view returns (uint256);

    function estimateSwapRateBumpUsdc(uint256 _deposit)
        external
        view
        returns (uint256);

    function getCurrentPrice(StableCoins _coin) external view returns (int256);

    function getSwapRateBumpUsdc() external view returns (uint256);

    function withdrawLiquidity(address receiver, uint256 amount)
        external
        returns (bool);
}
