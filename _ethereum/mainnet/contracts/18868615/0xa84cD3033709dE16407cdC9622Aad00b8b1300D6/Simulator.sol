// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
pragma abicoder v2;

import "./ISwapRouter.sol";
import "./IUniswapV3PoolImmutables.sol";
import "./IUniswapV2Router01.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ISimulator.sol";

contract Simulator is Ownable, ISimulator {
    address public routerV2;
    address public routerV3;
    address public weth;

    event Bought(uint256 amount);
    event Sold(uint256 amount);

    constructor(address _weth) {
        weth = _weth;
    }

    function simulateV2(address router, address token) external onlyOwner {
        IERC20(weth).approve(router, type(uint256).max);
        IERC20(token).approve(router, type(uint256).max);
        buyV2(router, token);
        sellV2(router, token);
    }

    function simulateV3(
        address router,
        address token,
        address pair
    ) external onlyOwner {
        IERC20(weth).approve(router, type(uint256).max);
        IERC20(token).approve(router, type(uint256).max);
        buyV3(router, token, pair);
        sellV3(router, token, pair);
    }

    function buyV2(address router, address token) private {
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = token;
        emit Bought(
            IUniswapV2Router01(router).swapExactTokensForTokens(
                IERC20(weth).balanceOf(address(this)),
                0,
                path,
                address(this),
                block.timestamp
            )[1]
        );
    }

    function sellV2(address router, address token) private {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = weth;
        emit Sold(
            IUniswapV2Router01(router).swapExactTokensForTokens(
                IERC20(token).balanceOf(address(this)),
                0,
                path,
                address(this),
                block.timestamp
            )[1]
        );
    }

    function buyV3(
        address router,
        address token,
        address pair
    ) private {
        emit Bought(
            ISwapRouter(router).exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: weth,
                    tokenOut: token,
                    fee: IUniswapV3PoolImmutables(pair).fee(),
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: IERC20(weth).balanceOf(address(this)),
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            )
        );
    }

    function sellV3(
        address router,
        address token,
        address pair
    ) private {
        emit Sold(
            ISwapRouter(router).exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: token,
                    tokenOut: weth,
                    fee: IUniswapV3PoolImmutables(pair).fee(),
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: IERC20(token).balanceOf(address(this)),
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            )
        );
    }
}
