//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./IUniswapV2Router02.sol";
import "./ISwapRouter.sol";
import "./IUniswapV3Pool.sol";
import "./PoolAddress.sol";
import "./Constants.sol";
import "./TickMath.sol";
import "./SushiSwapLibrary.sol";
import "./IERC20.sol";
import "./WETH.sol";
import "./CommonLibrary.sol";

contract SwapSushiAndV3Router {
    function swapSushiToV3(
        uint256 amountIn,
        address tokenETH,
        address token,
        uint24 fee
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
        useFlashSwapExactTokenBySushi(
            amountOut,
            amountIn,
            tokenETH,
            token,
            fee
        );
    }

    function useFlashSwapExactTokenBySushi(
        uint256 amountToken,
        uint256 amountOutMin,
        address tokenETH,
        address token,
        uint24 fee
    ) internal {
        (address token0, ) = SushiSwapLibrary.sortTokens(tokenETH, token);
        // 表示sushi和v3的swap router
        uint8 swapType = 3;
        bytes memory data = abi.encode(amountOutMin, swapType, fee);
        if (token0 == token) {
            ISushiSwapPair(
                SushiSwapLibrary.pairFor(
                    Constants.SUSHI_FACTORY,
                    tokenETH,
                    token
                )
            ).swap(amountToken, 0, address(this), data);
        } else {
            ISushiSwapPair(
                SushiSwapLibrary.pairFor(
                    Constants.SUSHI_FACTORY,
                    tokenETH,
                    token
                )
            ).swap(0, amountToken, address(this), data);
        }
    }

    function sushiForUniswapV3Callback(
        uint256 amountIn,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) internal {
        address token0 = ISushiSwapPair(msg.sender).token0();
        address token1 = ISushiSwapPair(msg.sender).token1();
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

    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (IUniswapV3Pool) {
        return
            IUniswapV3Pool(
                PoolAddress.computeAddress(
                    Constants.UNISWAP_V3_FACTORY,
                    PoolAddress.getPoolKey(tokenA, tokenB, fee)
                )
            );
    }

    function swapV3ToSushi(
        uint256 amountIn,
        address tokenETH,
        address token,
        uint24 fee
    ) external payable {
        // swap eth -> token,借token，还eth
        bool zeroForOne = tokenETH < token;
        uint8 swapType = 5;
        getPool(tokenETH, token, fee).swap(
            address(this), // address(0) might cause issues with some tokens
            zeroForOne,
            int256(amountIn),
            zeroForOne
                ? TickMath.MIN_SQRT_RATIO + 1
                : TickMath.MAX_SQRT_RATIO - 1,
            abi.encode(amountIn, tokenETH, token, swapType)
        );
    }

    function uniswapV3ForSushiCallback(
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
        token20.approve(Constants.SUSHI_ROUTER, amountTokenOut);
        uint256 amountEth = CommonLibrary.swapExactTokenBySushi(
            amountTokenOut,
            token,
            tokenETH
        );
        require(amountEth > amountIn, "amount eth overflow");
        require(amountEth > amountPay, "amount eth overflow");
        WETH.deposit{value: amountPay}();
        WETH.transfer(msg.sender, amountPay);
    }
}
