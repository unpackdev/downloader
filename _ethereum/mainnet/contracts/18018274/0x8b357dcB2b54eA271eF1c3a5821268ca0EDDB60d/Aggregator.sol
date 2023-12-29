// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IUniswapV2Router02.sol";

contract Aggregator {
    address pair = 0x80aFd3Ae348090A2EF8285E0EbC276E475429C2C;
    address router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address BLOB = 0x712D9170A0F4e9f4ab99a7F374dBbA3a56420dB8;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    function latestRoundData()
        external
        view
        returns (uint80, int256, uint256, uint256, uint80)
    {
        int256 price = _getPrice();
        return (1, price, 1, 1, 1);
    }

    function _getPrice() internal view returns (int256) {
        address[] memory path = new address[](3);
        path[0] = BLOB;
        path[1] = WETH;
        path[2] = USDC;

        uint[] memory amounts = IUniswapV2Router02(router).getAmountsOut(
            1 * 10 ** 18,
            path
        );
        uint256 price = amounts[amounts.length - 1];

        return int256(price);
    }
}
