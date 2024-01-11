// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2021 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IUniswapV3Quoter {
    struct QuoteExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }
        function quoteExactInputSingle(QuoteExactInputSingleParams memory params)
        external returns (
            uint256 amountOut,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        );
}

interface IUniswapV3Pool {
    function fee() external view returns (uint24);
}

contract UniswapV3Sampler {
    /// @dev Gas limit for UniswapV3 calls. This is 100% a guess.
    uint256 private constant QUOTE_GAS = 300e3;
    struct UniswapV3SamplerOpts{
        IUniswapV3Quoter quoter;
        IUniswapV3Pool pool;
    }

    /// @dev Sample sell quotes from UniswapV3.
    /// @param opts UniswapV3Sampler Quoter contract.
    /// @param takerTokenAmounts Taker token sell amount for each sample.
    /// @return makerTokenAmounts Maker amounts bought at each taker token
    ///         amount.
    function sampleSellsFromUniswapV3(
        UniswapV3SamplerOpts memory opts,
        address takerToken,
        address makerToken,
        uint256[] memory takerTokenAmounts
    ) public returns (uint256[] memory makerTokenAmounts) {
        makerTokenAmounts = new uint256[](takerTokenAmounts.length);

        uint24 fee = opts.pool.fee();
        for (uint256 i = 0; i < takerTokenAmounts.length; ++i) {
            // Pick the best result from all the paths.
            (uint256 topBuyAmount, , ,) = opts.quoter.quoteExactInputSingle{gas: QUOTE_GAS}(
                IUniswapV3Quoter.QuoteExactInputSingleParams({
                        tokenIn: takerToken,
                        tokenOut: makerToken,
                        fee: fee,
                        amountIn: takerTokenAmounts[i],
                        sqrtPriceLimitX96: 0
                    })
            );
            // Break early if we can't complete the buys.
            if (topBuyAmount == 0) {
                break;
            }
            makerTokenAmounts[i] = topBuyAmount;
        }
    }
}
