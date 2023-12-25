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

    constructor(
        address _routerV2,
        address _routerV3,
        address _weth
    ) {
        routerV2 = _routerV2;
        routerV3 = _routerV3;
        weth = _weth;
        IERC20(_weth).approve(_routerV2, type(uint256).max);
        IERC20(_weth).approve(_routerV3, type(uint256).max);
    }

    function simulateV2(address token) external onlyOwner {
        buyV2(token);
        sellV2(token);
    }

    function simulateV3(address token, address pair) external onlyOwner {
        buyV3(token, pair);
        sellV3(token, pair);
    }

    function buyV2(address token) private {
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = token;
        emit Bought(
            IUniswapV2Router01(routerV2).swapExactTokensForTokens(
                IERC20(weth).balanceOf(address(this)),
                0,
                path,
                address(this),
                block.timestamp
            )[1]
        );
    }

    function sellV2(address token) private {
        IERC20(token).approve(routerV2, type(uint256).max);
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = weth;
        emit Sold(
            IUniswapV2Router01(routerV2).swapExactTokensForTokens(
                IERC20(token).balanceOf(address(this)),
                0,
                path,
                address(this),
                block.timestamp
            )[1]
        );
    }

    function buyV3(address token, address pair) private {
        emit Bought(
            ISwapRouter(routerV3).exactInputSingle(
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

    function sellV3(address token, address pair) private {
        emit Sold(
            ISwapRouter(routerV3).exactInputSingle(
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
