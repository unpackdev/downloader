// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface IAMM {
    function swapExactInput(
        address tokenA,
        address tokenB,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOutMin
    ) external returns (uint256);

    function swap(
        address tokenA,
        address tokenB,
        uint256 amountIn,
        uint256 amountOutMin,
        address poolAddress
    ) external returns (uint256);

    function buySweep(
        address token,
        uint256 amountIn,
        uint256 amountOutMin
    ) external returns (uint256);

    function sellSweep(
        address token,
        uint256 amountIn,
        uint256 amountOutMin
    ) external returns (uint256);

    function sequencer() external view returns (address);

    function pool() external view returns (address);

    function getTWAPrice() external view returns (uint256 twaPrice);

    function getPrice() external view returns (uint256 price);
    
    function getRate() external view returns (uint256 rate);

    function getPositions(uint256) external view returns (uint256 usdxAmount, uint256 sweepAmount, uint256 lp);
}
