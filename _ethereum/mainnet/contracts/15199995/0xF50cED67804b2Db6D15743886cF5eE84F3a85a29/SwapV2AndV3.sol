//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./IUniswapV2Router02.sol";
import "./ISwapRouter.sol";
import "./IUniswapV3Pool.sol";
import "./TickMath.sol";
import "./UniswapV2Library.sol";
import "./IERC20.sol";
import "./WETH.sol";
import "./CommonLibrary.sol";
import "./Constants.sol";
import "./UniswapV3Library.sol";

contract SwapV2AndV3Router {
    function swapV2ToV3(
        uint256 amountIn,
        address tokenETH,
        address token,
        uint24 fee
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
        useFlashSwapExactTokenByV2(amountOut, amountIn, tokenETH, token, fee);
    }

    function useFlashSwapExactTokenByV2(
        uint256 amountToken,
        uint256 amountOutMin,
        address tokenETH,
        address token,
        uint24 fee
    ) internal {
        (address token0, ) = UniswapV2Library.sortTokens(tokenETH, token);
        // 表示v2和v3的swap router
        uint8 swapType = 4;
        bytes memory data = abi.encode(amountOutMin, swapType, fee);
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

    function uniswapV2ForUniswapV3Callback(
        uint256 amountIn,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
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
            IWETH WETH = IWETH(token1);
            IERC20 token = IERC20(token0);
            token.approve(Constants.UNISWAP_V3_ROUTER, amount0);
            uint256 amountOut = CommonLibrary.swapExactTokenByV3(
                token0,
                token1,
                amount0,
                data
            );
            require(amountOut >= amountIn, "amount less min");
            WETH.transfer(msg.sender, amountIn);
        } else {
            IWETH WETH = IWETH(token0);
            IERC20 token = IERC20(token1);
            token.approve(Constants.UNISWAP_V3_ROUTER, amount1);
            uint256 amountOut = CommonLibrary.swapExactTokenByV3(
                token1,
                token0,
                amount1,
                data
            );
            require(amountOut >= amountIn, "amount less min");
            WETH.transfer(msg.sender, amountIn);
        }
    }

    function swapV3ToV2(
        uint256 amountIn,
        address tokenETH,
        address token,
        uint24 fee
    ) public {
        // swap eth -> token,借token，还eth
        bool zeroForOne = tokenETH < token;
        uint8 swapType = 6;

        UniswapV3Library.getPool(tokenETH, token, fee).swap(
            address(this), // address(0) might cause issues with some tokens
            zeroForOne,
            int256(amountIn),
            zeroForOne
                ? TickMath.MIN_SQRT_RATIO + 1
                : TickMath.MAX_SQRT_RATIO - 1,
            abi.encode(amountIn, tokenETH, token, swapType)
        );
    }

    function uniswapV3ForV2Callback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) internal {
        (uint256 amountIn, address tokenETH, address token) = abi.decode(
            data,
            (uint256, address, address)
        );
        IWETH WETH = IWETH(tokenETH);
        IERC20 token20 = IERC20(token);

        uint256 amountPay = amount0Delta > 0
            ? uint256(amount0Delta)
            : uint256(amount1Delta);
        uint256 amountTokenOut = amount0Delta > 0
            ? uint256(-amount1Delta)
            : uint256(-amount0Delta);
        token20.approve(Constants.UNISWAP_V2_ROUTER, amountTokenOut);

        uint256 amountEth = CommonLibrary.swapExactTokenByV2(
            amountTokenOut,
            token,
            tokenETH
        );
        require(amountEth > amountIn, "amount eth overflow");
        require(amountEth > amountPay, "amount eth overflow");
        WETH.transfer(msg.sender, amountPay);
    }
}
