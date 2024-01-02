// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

import "./IAdapter.sol";
import "./GasConsumer.sol";

import {IUniswapV2Router02} from
    "@gearbox-protocol/integrations-v3/contracts/integrations/uniswap/IUniswapV2Router02.sol";
import "./IUniswapV2Adapter.sol";

import "./ICreditFacadeV3.sol";
import "./ISwapper.sol";
import "./SwapOperation.sol";
import "./SwapTask.sol";
import "./SwapQuote.sol";
import "./RouterComponent.sol";

contract UniswapV2Swapper is ISwapper, GasConsumer {
    using SwapTaskOps for SwapTask;
    using SwapQuoteOps for SwapQuote;

    /// @notice Pathfinder Component ID
    uint8 public override getComponentId = RC_UNISWAP_V2_SWAPPER;

    // Contract version
    uint256 public constant override version = 1;

    constructor(address _router) GasConsumer(_router) {}

    function getBestDirectPairSwap(SwapTask memory swapTask, address adapter)
        public
        view
        override
        returns (SwapQuote memory quote)
    {
        address[] memory path = new address[](2); // F:[PUV2-2,3,4]
        path[0] = swapTask.tokenIn; // F:[PUV2-2,3,4]
        path[1] = swapTask.tokenOut; // F:[PUV2-2,3,4]

        if (IUniswapV2Adapter(adapter).isPairAllowed(swapTask.tokenIn, swapTask.tokenOut)) {
            quote = getQuoteByPath(swapTask, adapter, path);
        } // F:[PUV2-2,3,4]
    }

    function getQuoteByPath(SwapTask memory swapTask, address adapter, address[] memory path)
        internal
        view
        returns (SwapQuote memory quote)
    {
        uint256 resultAmount; // F:[PUV2-2,3,4, 5,6]

        if (swapTask.isInputTask()) {
            try IUniswapV2Router02(IAdapter(adapter).targetContract()).getAmountsOut(swapTask.amount, path) // F:[PUV2-2,3,5]
            returns (uint256[] memory amountsOut) {
                resultAmount = amountsOut[amountsOut.length - 1]; // F:[PUV2-2,3,5]
            } catch {}
        } else {
            try IUniswapV2Router02(IAdapter(adapter).targetContract()).getAmountsIn(swapTask.amount, path) returns (
                uint256[] memory amountsIn
            ) {
                resultAmount = amountsIn[0]; // F:[PUV2-2,4,6]
            } catch {}
        }

        if (resultAmount != 0) {
            quote.amount = resultAmount;
            quote.found = true;
            quote.multiCall = toMulticall(swapTask, adapter, path, resultAmount);

            for (uint256 i; i < path.length - 1;) {
                quote.gasUsage += gasUsageByAdapterAndTokens(adapter, path[i], path[i + 1]);

                unchecked {
                    ++i;
                }
            }
        }
    }

    function toMulticall(SwapTask memory swapTask, address adapter, address[] memory path, uint256 amount)
        internal
        view
        returns (MultiCall memory)
    {
        if (swapTask.swapOperation == SwapOperation.EXACT_INPUT_DIFF) {
            return MultiCall({
                target: adapter,
                callData: abi.encodeWithSelector(
                    IUniswapV2Adapter.swapDiffTokensForTokens.selector,
                    swapTask.leftoverAmount,
                    0,
                    path,
                    block.timestamp + 3600
                    )
            });
        } // F:[PUV2-3,5]

        if (swapTask.swapOperation == SwapOperation.EXACT_INPUT) {
            return MultiCall({
                target: adapter,
                callData: abi.encodeWithSelector(
                    IUniswapV2Router02.swapExactTokensForTokens.selector,
                    swapTask.amount,
                    0,
                    path,
                    swapTask.creditAccount,
                    block.timestamp + 3600
                    )
            });
        } // F:[PUV2-3,5]
        if (swapTask.swapOperation == SwapOperation.EXACT_OUTPUT) {
            return MultiCall({
                target: adapter,
                callData: abi.encodeWithSelector(
                    IUniswapV2Router02.swapTokensForExactTokens.selector,
                    swapTask.amount,
                    type(uint256).max,
                    path,
                    swapTask.creditAccount,
                    block.timestamp + 3600
                    )
            });
        } // F:[PUV2-4,6]

        revert UnsupportedSwapOperation(swapTask.swapOperation);
    }
}
