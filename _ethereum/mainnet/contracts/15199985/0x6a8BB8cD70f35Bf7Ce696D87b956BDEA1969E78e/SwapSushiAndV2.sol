//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./IUniswapV2Router02.sol";
import "./UniswapV2Library.sol";
import "./SushiSwapLibrary.sol";
import "./CommonLibrary.sol";
import "./Constants.sol";

import "./IERC20.sol";
import "./WETH.sol";

contract SwapSushiAndV2Router {
    event SushiLog(uint256 amountEth, uint256 amonutOut);

    function swapSushiToV2(
        uint256 amountIn,
        address tokenETH,
        address token
    ) public {
        (uint256 reserveIn, uint256 reserveOut) = SushiSwapLibrary.getReserves(
            Constants.SUSHI_FACTORY,
            tokenETH,
            token
        );
        uint256 amountOut = SushiSwapLibrary.getAmountOut(
            amountIn,
            reserveIn,
            reserveOut
        );
        useFlashSwapExactTokenBySushi(amountOut, amountIn, tokenETH, token);
    }

    function useFlashSwapExactTokenBySushi(
        uint256 amountToken,
        uint256 amountOutMin,
        address tokenETH,
        address token
    ) public {
        (address token0, ) = SushiSwapLibrary.sortTokens(tokenETH, token);
        uint8 swapType = 2;
        bytes memory data = abi.encode(amountOutMin, swapType, 0);
        // 提前获得token,这个地方就是uniswapV2 swap获取token，路径ETH -> token
        if (token0 == token) {
            IUniswapV2Pair(
                SushiSwapLibrary.pairFor(
                    Constants.SUSHI_FACTORY,
                    tokenETH,
                    token
                )
            ).swap(amountToken, 0, address(this), data);
        } else {
            IUniswapV2Pair(
                SushiSwapLibrary.pairFor(
                    Constants.SUSHI_FACTORY,
                    tokenETH,
                    token
                )
            ).swap(0, amountToken, address(this), data);
        }
    }

    // 使用swapv2ToSushi
    // 1. 输入ETH amountIn的数据量，获得对应的Token amountOut
    // 2. 使用Token的amountOut数量输入，然后通过flashswap提前获得token
    // 3. 把发送的token卖到sushi上，获得ETH，然后还给uniswap v2
    function swapV2ToSushi(
        uint256 amountIn,
        address tokenETH,
        address token
    ) public {
        (uint256 reserveIn, uint256 reserveOut) = UniswapV2Library.getReserves(
            Constants.UNISWAP_V2_FACTORY,
            tokenETH,
            token
        );
        uint256 amountOut = UniswapV2Library.getAmountOut(
            amountIn,
            reserveIn,
            reserveOut
        );
        useFlashSwapExactTokenByV2(amountOut, amountIn, tokenETH, token);
    }

    function useFlashSwapExactTokenByV2(
        uint256 amountToken,
        uint256 amountOutMin,
        address tokenETH,
        address token
    ) public {
        (address token0, ) = UniswapV2Library.sortTokens(tokenETH, token);
        uint8 swapType = 1;
        bytes memory data = abi.encode(amountOutMin, swapType, 0);
        // 提前获得token,这个地方就是uniswapV2 swap获取token，路径ETH -> token
        if (token0 == token) {
            IUniswapV2Pair(
                UniswapV2Library.pairFor(
                    Constants.UNISWAP_V2_FACTORY,
                    tokenETH,
                    token
                )
            ).swap(amountToken, 0, address(this), data);
        } else {
            IUniswapV2Pair(
                UniswapV2Library.pairFor(
                    Constants.UNISWAP_V2_FACTORY,
                    tokenETH,
                    token
                )
            ).swap(0, amountToken, address(this), data);
        }
    }

    function sushiForUniswapV2CallBack(
        uint256 amountIn,
        uint256 amount0,
        uint256 amount1
    ) internal {
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        require(
            msg.sender ==
                SushiSwapLibrary.pairFor(
                    Constants.SUSHI_FACTORY,
                    token0,
                    token1
                ),
            "pair not equal pool"
        );
        require(amount0 > 0 || amount1 > 0, "amount not right");
        if (amount0 > 0) {
            IWETH WETH = IWETH(token1);
            IERC20 token = IERC20(token0);
            token.approve(Constants.UNISWAP_V2_ROUTER, amount0);
            uint256 amountOut = CommonLibrary.swapExactTokenByV2(
                amount0,
                token0,
                token1
            );
            require(amountOut >= amountIn, "amount less min");
            WETH.transfer(msg.sender, amountIn);
        } else {
            IWETH WETH = IWETH(token1);
            IERC20 token = IERC20(token1);
            token.approve(Constants.UNISWAP_V2_ROUTER, amount1);
            uint256 amountOut = CommonLibrary.swapExactTokenByV2(
                amount1,
                token1,
                token0
            );
            require(amountOut >= amountIn, "amount less min");
            WETH.transfer(msg.sender, amountIn);
        }
    }

    function uniswapV2ForSushiCallback(
        uint256 amountIn,
        uint256 amount0,
        uint256 amount1
    ) internal {
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        require(
            msg.sender ==
                UniswapV2Library.pairFor(
                    Constants.UNISWAP_V2_FACTORY,
                    token0,
                    token1
                ),
            "pair not equal pool"
        );
        require(amount0 > 0 || amount1 > 0, "amount not right");
        if (amount0 > 0) {
            // 实际上就是WETH
            IWETH WETH = IWETH(token1);
            IERC20 token = IERC20(token0);
            token.approve(Constants.SUSHI_ROUTER, amount0);
            uint256 amountOut = CommonLibrary.swapExactTokenBySushi(
                amount0,
                token0,
                token1
            );
            require(amountOut >= amountIn, "amount less min");
            WETH.transfer(msg.sender, amountIn);
        } else {
            IWETH WETH = IWETH(token0);
            IERC20 token = IERC20(token1);
            token.approve(Constants.SUSHI_ROUTER, amount1);
            uint256 amountOut = CommonLibrary.swapExactTokenBySushi(
                amount1,
                token1,
                token0
            );
            require(amountOut >= amountIn, "amount less min");
            WETH.transfer(msg.sender, amountIn);
        }
    }
}
