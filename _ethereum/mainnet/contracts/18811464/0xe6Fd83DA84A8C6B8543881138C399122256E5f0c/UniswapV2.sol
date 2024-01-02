//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./LibAsset.sol";
import "./IUniswapV2Router02.sol";
import "./IERC20.sol";

contract UniswapV2 {
    struct UniswapV2Data {
        address[] path;
        uint256 deadline;
    }

    function swapOnUniswapV2(
        address fromToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal returns (uint256 receivedAmount) {
        UniswapV2Data memory data = abi.decode(payload, (UniswapV2Data));

        LibAsset.approveERC20(IERC20(fromToken), exchange, fromAmount);

        uint256[] memory amounts = new uint256[](data.path.length);
        amounts = IUniswapV2Router02(exchange).swapExactTokensForTokens(
            fromAmount,
            1,
            data.path,
            address(this),
            data.deadline
        );

        receivedAmount = amounts[amounts.length - 1];
    }

    function quoteOnUniswapV2(
        address fromToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal view returns (uint256 receivedAmount) {
        UniswapV2Data memory data = abi.decode(payload, (UniswapV2Data));

        uint256[] memory amounts = new uint256[](data.path.length);

        amounts = IUniswapV2Router02(exchange).getAmountsOut(fromAmount, data.path);
        receivedAmount = amounts[amounts.length - 1];
    }
}