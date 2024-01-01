// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IERC20.sol";

contract ovPoolBase {
    IUniswapV2Router02 public immutable uniswapV2Router;

    event PairCreated(address indexed tokenA, address indexed tokenB, address pair);
    event LiquidityAdded(address indexed tokenA, address indexed tokenB, uint amountA, uint amountB);
    event RemainderTransferred(address indexed token, address indexed recipient, uint amount);

    constructor() {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    function buyTokensAsLiquidity(address tokenA, address tokenB, uint256 minAmountTokenA, uint256 minAmountTokenB, uint256 deadline) external payable {
        findOrCreatePair(tokenA, tokenB);

        uint256 halfEthAmount = msg.value / 2;

        uint256 boughtTokenAAmount = thisPairSwapExactETHForTokens(tokenA, halfEthAmount, minAmountTokenA, deadline);
        uint256 boughtTokenBAmount = thisPairSwapExactETHForTokens(tokenB, msg.value - halfEthAmount, minAmountTokenB, deadline);

        checkAndIncreaseAllowance(tokenA, boughtTokenAAmount);
        checkAndIncreaseAllowance(tokenB, boughtTokenBAmount);

        addLiquidity(tokenA, tokenB, boughtTokenAAmount, boughtTokenBAmount, minAmountTokenA, minAmountTokenB, deadline);

        transferTokensRemaining(tokenA);
        transferTokensRemaining(tokenB);
    }

    function addOwnedTokensAsLiquidity(address tokenA, address tokenB, uint256 amountA, uint256 amountB, uint256 minAmountTokenA, uint256 minAmountTokenB, uint256 deadline) external {
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        findOrCreatePair(tokenA, tokenB);
        checkAndIncreaseAllowance(tokenA, amountA);
        checkAndIncreaseAllowance(tokenB, amountB);

        addLiquidity(tokenA, tokenB, amountA, amountB, minAmountTokenA, minAmountTokenB, deadline);

        transferTokensRemaining(tokenA);
        transferTokensRemaining(tokenB);
    }

    function findOrCreatePair(address tokenA, address tokenB) internal returns (address) {
        IUniswapV2Factory factory = IUniswapV2Factory(uniswapV2Router.factory());
        address pair = factory.getPair(tokenA, tokenB);
        if (pair == address(0)) {
            pair = factory.createPair(tokenA, tokenB);
            emit PairCreated(tokenA, tokenB, pair);
        }
        return pair;
    }

    function thisPairSwapExactETHForTokens(address token, uint256 ethAmount, uint256 minAmountToken, uint256 deadline) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = token;

        uint[] memory amounts = uniswapV2Router.swapExactETHForTokens{ value: ethAmount }(minAmountToken, path, address(this), deadline);

        return amounts[1];
    }

    function checkAndIncreaseAllowance(address token, uint256 amount) internal {
        if (IERC20(token).allowance(address(this), address(uniswapV2Router)) < amount) {
            IERC20(token).approve(address(uniswapV2Router), type(uint256).max);
        }
    }

    function addLiquidity(address tokenA, address tokenB, uint256 amountA, uint256 amountB, uint256 minAmountTokenA, uint256 minAmountTokenB, uint256 deadline) internal {
        uniswapV2Router.addLiquidity(tokenA, tokenB, amountA, amountB, minAmountTokenA, minAmountTokenB, msg.sender, deadline);
        emit LiquidityAdded(tokenA, tokenB, amountA, amountB);
    }

    function transferTokensRemaining(address token) internal {
        uint256 remainder = IERC20(token).balanceOf(address(this));
        if (remainder > 0) {
            IERC20(token).transfer(msg.sender, remainder);
            emit RemainderTransferred(token, msg.sender, remainder);
        }
    }

    receive() external payable {}
}
