// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IEGMC.sol";

contract EGMCSwapManager is Ownable {
    using SafeMath for uint;

    IEGMC public immutable token;

    constructor (
        address _token
    ) {
        token = IEGMC(_token);
    }

    function addLiquidity(uint tokenAmount, uint wethAmount) external {
        require(
            msg.sender == address(token),
            "Only EGMC token can call this function"
        );

        token.transferFrom(address(token), address(this), tokenAmount);
        IERC20(token.WETH()).transferFrom(address(token), address(this), wethAmount);

        IUniswapV2Router02 router = IUniswapV2Router02(token.uniswapV2Router());

        token.approve(address(router), tokenAmount);
        IERC20(token.WETH()).approve(address(router), wethAmount);

        router.addLiquidity(
            address(token),
            token.WETH(),
            tokenAmount,
            wethAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            token.liquidityWallet(),
            block.timestamp + 30 seconds
        );
    }

    function swapToWeth(uint tokenAmount) external {
        require(
            msg.sender == address(token),
            "Only EGMC token can call this function"
        );

        token.transferFrom(address(token), address(this), tokenAmount);
        
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = token.WETH();

        IUniswapV2Router02 router = IUniswapV2Router02(token.uniswapV2Router());
        token.approve(address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        IERC20(token.WETH()).transfer(address(token), IERC20(token.WETH()).balanceOf(address(this)));
    }

    function recover(address _token) external onlyOwner {
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }
}