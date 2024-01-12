// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Callee.sol";

contract DemoFlash is IUniswapV2Callee {
    address private constant UNISWAP_V2_FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private constant SUSHISWAP_FACTORY =
        0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;

    address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    event Addr(address addr, string m);
    event Amt(uint256 _0, uint256 _1, string m);
    event Amt(uint256 _0, string m);

    event Sqrt(uint256 input, uint256 output);
    event CalX(int256 x1, int256 x2);

    event Arbitrage(address tokenA, address tokenB, uint256 output);

    event ArbitrageFailed(
        address tokenA,
        address tokenB,
        uint256 minimumOutput
    );

    event UniswapCalled(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes data
    );

    function flash() public payable {
        emit Amt(msg.value, "msg.value");
        {
            require(msg.value > 0, "send some maneyy man");
            (bool _success, ) = WETH.call{value: msg.value}(
                abi.encodeWithSignature("deposit()")
            );
            require(_success, "WETH deposit failing");
        }
        emit Amt(msg.value, "msg.value");

        IUniswapV2Pair uniswapPair = IUniswapV2Pair(
            IUniswapV2Factory(UNISWAP_V2_FACTORY).getPair(USDC, WETH)
        );
        IUniswapV2Pair sushiswapPair = IUniswapV2Pair(
            IUniswapV2Factory(SUSHISWAP_FACTORY).getPair(USDC, WETH)
        );

        uniswapPair.swap(
            0,
            0.1 ether,
            address(this),
            "0x" //abi.encode(token0, token1, pullToken1, minimumOutputA, uniswapPair, sushiswapPair, x, y, z, 2)
        );
    }

    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        emit UniswapCalled(sender, amount0, amount1, data);

        // (uint256 r0, uint256 r1, ) = IUniswapV2Pair(msg.sender).getReserves();
        // address token0 = IUniswapV2Pair(msg.sender).token0();
        // address token1 = IUniswapV2Pair(msg.sender).token1();
        // uint256 bal0PairBefore = IERC20(token0).balanceOf(msg.sender);
        // uint256 bal1PairBefore = IERC20(token1).balanceOf(msg.sender);

        // uint256 submitAmt = UniswapV2Library.getAmountIn(amount1, r0, r1);
        uint256 submitAmt = (amount1 * 1000) / 997 + 1;
        emit Amt(submitAmt, "submitAmt");

        IERC20(WETH).transfer(msg.sender, submitAmt);
    }
}
