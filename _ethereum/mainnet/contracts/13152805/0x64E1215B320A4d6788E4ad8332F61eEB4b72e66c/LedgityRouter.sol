pragma solidity ^0.6.12;

import "./SafeERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./ILedgity.sol";
import "./ILedgityRouter.sol";

// SPDX-License-Identifier: Unlicensed
contract LedgityRouter is ILedgityRouter {
    IUniswapV2Factory public immutable factory;
    IUniswapV2Router02 public immutable uniswapRouter;

    constructor(address _router) public {
        IUniswapV2Router02 _uniswapRouter = IUniswapV2Router02(_router);
        factory = IUniswapV2Factory(_uniswapRouter.factory());
        uniswapRouter = _uniswapRouter;
    }

    function addLiquidityBypassingFee(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external override returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        SafeERC20.safeTransferFrom(tokenA, msg.sender, address(this), amountADesired);
        SafeERC20.safeTransferFrom(tokenB, msg.sender, address(this), amountBDesired);
        SafeERC20.safeApprove(tokenA, address(uniswapRouter), amountADesired);
        SafeERC20.safeApprove(tokenB, address(uniswapRouter), amountBDesired);
        (amountA, amountB, liquidity) = uniswapRouter.addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, to, deadline);
        _refund(tokenA, msg.sender);
        _refund(tokenB, msg.sender);
    }

    function removeLiquidityBypassingFee(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external override returns (uint256 amountA, uint256 amountB) {
        address pair = factory.getPair(tokenA, tokenB);
        SafeERC20.safeTransferFrom(pair, msg.sender, address(this), liquidity);
        SafeERC20.safeApprove(pair, address(uniswapRouter), liquidity);
        (amountA, amountB) = uniswapRouter.removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, address(this), deadline);
        _refund(tokenA, to);
        _refund(tokenB, to);
    }

    function _refund(address token, address to) private {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance != 0) {
            SafeERC20.safeTransfer(token, to, balance);
        }
    }
}
