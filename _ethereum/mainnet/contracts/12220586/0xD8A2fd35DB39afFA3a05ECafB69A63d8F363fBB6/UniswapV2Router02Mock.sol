// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";

contract UniswapV2Router02Mock {
    address public WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    uint256 public lastAmountsOutMin;

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts) {
        (deadline);
        IERC20(path[1]).transfer(to, 0);
        uint256[] memory amountsOut = new uint256[](2);
        amountsOut[0] = msg.value;
        amountsOut[1] = amountOutMin;
        lastAmountsOutMin = amountOutMin;
        return amountsOut;
    }

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        pure
        returns (uint256[] memory amounts)
    {
        (path);
        uint256[] memory amountsOut = new uint256[](2);
        amountsOut[0] = amountIn;
        amountsOut[1] = amountIn;
        return amountsOut;
    }
}
