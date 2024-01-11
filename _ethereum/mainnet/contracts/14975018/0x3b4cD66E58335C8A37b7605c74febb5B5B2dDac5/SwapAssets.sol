// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;
import "./UniswapV3Router.sol";
import "./UniswapV2Router.sol";
import "./PancakeswapRouter.sol";
import "./SwapInforRegistry.sol";
import "./Helpers.sol";

contract SwapAssets is 
    UniswapV3Router,
    UniswapV2Router,
    PancakeswapRouter,
    SwapInforRegistry {

    function tradeExecute(
        address recipient,
        address loanedAssest,
        uint256 loanedAmount,
        address[] memory tradeAssets,
        uint16[] memory tradeDexes
    ) internal returns (uint256 amountOut){
        require(loanedAmount > 0, "loaned amount is 0");
        require(tradeDexes.length == tradeAssets.length, "Invalid trade params");
        require(
            tradeAssets[tradeAssets.length - 1] == loanedAssest,
            "end trade assest must be equal to loaned assest"
        );
        amountOut = swapAsset(
            recipient,
            Helpers.getPaths(loanedAssest, tradeAssets[0]),
            loanedAmount,
            tradeDexes[0]
        );
        for (uint i = 1; i < tradeAssets.length; i++) {
            amountOut = swapAsset(
                recipient,
                Helpers.getPaths(tradeAssets[i - 1], tradeAssets[i]),
                amountOut,
                tradeDexes[i]
            );
        }
    }

    function swapAsset(
        address recipient,
        address[] memory path,
        uint256 amountIn,
        uint16 dexId
    ) internal returns (uint256 amountOut){
        if (dexId == UNISWAP_V3_ROUTER_ID) {
            uniswapV3Router = ISwapRouter(swapRouterInfos[dexId].router);
            amountOut = uniV3SwapSingle(
                recipient,
                path,
                amountIn,
                0,
                swapRouterInfos[dexId].poolFee,
                uint64(block.timestamp) + swapRouterInfos[dexId].deadline
            );
        } else if (dexId == UNISWAP_V2_ROUTER_ID) {
            uniswapV2Router = IUniswapV2Router02(swapRouterInfos[dexId].router);
            amountOut = uniV2Swap(
                recipient,
                path,
                amountIn,
                0,
                uint64(block.timestamp) + swapRouterInfos[dexId].deadline
            );
        } else if (dexId == SUSHISWAP_ROUTER_ID) {
            uniswapV2Router = IUniswapV2Router02(swapRouterInfos[dexId].router);
            amountOut = uniV2Swap(
                recipient,
                path,
                amountIn,
                0,
                uint64(block.timestamp) + swapRouterInfos[dexId].deadline
            );
        }
        else if (dexId == SIBASWAP_ROUTER_ID) {
            uniswapV2Router = IUniswapV2Router02(swapRouterInfos[dexId].router);
            amountOut = uniV2Swap(
                recipient,
                path,
                amountIn,
                0,
                uint64(block.timestamp) + swapRouterInfos[dexId].deadline
            );
        }
        else if (dexId == PANCAKE_ROUTER_ID) {
            pancakeswapRouter = IPancakeRouter02(swapRouterInfos[dexId].router);
            amountOut = pancakeSwap(
                recipient,
                path,
                amountIn,
                0,
                uint64(block.timestamp) + swapRouterInfos[dexId].deadline
            );
        }
    }
}