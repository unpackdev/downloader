// SPDX-License-Identifier: MIT
// @author: https://github.com/SHA-2048


pragma solidity ^0.8.0;

import "./IUniswapV2Router02.sol";
import "./IERC20.sol";

import "./ISwapRouter.sol";
import "./AllowanceChecker.sol";

contract UniswapV2SwapRouter is ISwapRouter, AllowanceChecker {

    IUniswapV2Router02 public uniswapRouter;

    constructor(IUniswapV2Router02 _uniswapRouter) {
        uniswapRouter = _uniswapRouter;
    }

    function weth() external view override returns(address) {
        return uniswapRouter.WETH();
    }

    function swapExactTokensForTokens(
        address[] memory _path,
        uint _supplyTokenAmount,
        uint _minOutput
    ) external override {

        require(_path[0] != _path[_path.length - 1], "Output token must not be given in input");

        IERC20(_path[0]).transferFrom(msg.sender, address(this), _supplyTokenAmount);

        approveIfNeeded(_path[0], address(uniswapRouter));

        uniswapRouter.swapExactTokensForTokens(
            _supplyTokenAmount,
            _minOutput,
            _path,
            address(msg.sender),
            block.timestamp + 1000
        );
    }

    function compound(
        address[] memory _path,
        uint _amount
    ) external override {

        IERC20(_path[0]).transferFrom(msg.sender, address(this), _amount);

        approveIfNeeded(_path[0], address(uniswapRouter));
        approveIfNeeded(uniswapRouter.WETH(), address(uniswapRouter));

        uniswapRouter.swapExactTokensForTokens(
            _amount / 2,
            0,
            _path,
            address(this),
            block.timestamp + 1000
        );

        uniswapRouter.addLiquidity(
            _path[0],
            uniswapRouter.WETH(),
            IERC20(_path[0]).balanceOf(address(this)),
            IERC20(uniswapRouter.WETH()).balanceOf(address(this)),
            0,
            0,
            address(msg.sender),
            block.timestamp + 1000
        );

        IERC20(_path[0]).transfer(msg.sender, IERC20(_path[0]).balanceOf(address(this)));
        IERC20(uniswapRouter.WETH()).transfer(msg.sender, IERC20(uniswapRouter.WETH()).balanceOf(address(this)));

    }

}
