//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./IERC20.sol";
import "./LibAsset.sol";
import "./LibUtil.sol";
import "./LibQuote.sol";

interface ISwapRouterUniV3 {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
}

interface ISwapQuoterUniV3 {
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);
}

abstract contract UniswapV3 {
    struct UniswapV3Data {
        bytes path;
        uint256 deadline;
    }

    function swapOnUniswapV3(
        address fromToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal returns (uint256 receivedAmount){
        UniswapV3Data memory data = abi.decode(payload, (UniswapV3Data));

        LibAsset.approveERC20(IERC20(fromToken), exchange, fromAmount);

        receivedAmount = ISwapRouterUniV3(exchange).exactInput(
            ISwapRouterUniV3.ExactInputParams({
                path: data.path,
                recipient: address(this),
                deadline: data.deadline,
                amountIn: fromAmount,
                amountOutMinimum: 1
            })
        );
    }

    function quoteOnUniswapV3(
        address,
        uint256 fromAmount,
        address targetExchange,
        bytes calldata payload
    ) internal returns (uint256 receivedAmount){
        UniswapV3Data memory data = abi.decode(payload, (UniswapV3Data));

        address exchangeQuoter = LibQuote.getQuoter(targetExchange);
        if (LibUtil.isZeroAddress(exchangeQuoter)){
            revert("Unimplement exchanger");
        }
        
        // TODO: need to generalize that  
        receivedAmount = ISwapQuoterUniV3(exchangeQuoter).quoteExactInput(
                data.path,
                fromAmount
        );
        return receivedAmount;
    }
}