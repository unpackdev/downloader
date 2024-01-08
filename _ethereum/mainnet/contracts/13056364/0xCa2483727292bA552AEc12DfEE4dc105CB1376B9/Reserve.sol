pragma solidity ^0.6.12;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";
import "./ILedgity.sol";
import "./IReserve.sol";

// SPDX-License-Identifier: Unlicensed
contract Reserve is IReserve, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Pair public override uniswapV2Pair;
    ILedgity public token;
    IERC20 public usdc;
    address public immutable timelock;

    modifier onlyToken {
        require(msg.sender == address(token), "Reserve: caller is not the token");
        _;
    }

    constructor(address uniswapRouter, address TOKEN, address USDC, address timelock_) public {
        require(timelock_ != address(0), "Reserve: invalid timelock address");
        uniswapV2Router = IUniswapV2Router02(uniswapRouter);
        token = ILedgity(TOKEN);
        usdc = IERC20(USDC);
        timelock = timelock_;
        uniswapV2Pair = IUniswapV2Pair(
            IUniswapV2Factory(IUniswapV2Router02(uniswapRouter).factory())
                .createPair(TOKEN, USDC)
        );
    }

    function buyAndBurn(uint256 usdcAmount) external override onlyOwner {
        address[] memory path = new address[](2);
        path[0] = address(usdc);
        path[1] = address(token);
        uint256 tokenBalanceBefore = token.balanceOf(address(this));
        SafeERC20.safeApprove(address(usdc) ,address(uniswapV2Router), usdcAmount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            usdcAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 tokensSwapped = token.balanceOf(address(this)).sub(tokenBalanceBefore);
        require(token.burn(tokensSwapped), "Reserve: burn failed");
        emit BuyAndBurn(tokensSwapped, usdcAmount);
    }

    function swapAndCollect(uint256 tokenAmount) external override onlyToken {
        uint256 usdcReceived = _swapTokensForUSDC(tokenAmount);
        emit SwapAndCollect(tokenAmount, usdcReceived);
    }

    function swapAndLiquify(uint256 tokenAmount) external override onlyToken {
        uint256 tokenBalance = token.balanceOf(address(this));
        uint256 half = tokenAmount;
        uint256 otherHalf = tokenAmount;
        if (tokenBalance < tokenAmount.mul(2)) {
            half = tokenBalance.div(2);
            otherHalf = tokenBalance.sub(half);
        }
        uint256 usdcReceived = _swapTokensForUSDC(otherHalf);
        SafeERC20.safeTransfer(address(token), address(uniswapV2Pair), half);
        SafeERC20.safeTransfer(address(usdc), address(uniswapV2Pair), usdcReceived);
        uniswapV2Pair.mint(timelock);
        emit SwapAndLiquify(otherHalf, usdcReceived, half);
    }

    function _swapTokensForUSDC(uint256 tokenAmount) private returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(usdc);
        uint256 usdcBalanceBefore = usdc.balanceOf(address(this));
        SafeERC20.safeApprove(address(token) ,address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 usdcSwapped = usdc.balanceOf(address(this)).sub(usdcBalanceBefore);
        return usdcSwapped;
    }
}
