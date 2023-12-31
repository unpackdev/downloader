// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract ArbBot is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IUniswapV2Router public uniswapRouter;

    event ArbitrageExecuted(address indexed sender, uint amountIn, uint amountReceived);
    event FundsAdded(address indexed sender, address token, uint amount);

    constructor(address _uniswapRouter) {
        uniswapRouter = IUniswapV2Router(_uniswapRouter);
    }

    // Function to add funds in the form of tokens
    function addFunds(address token, uint amount) external onlyOwner {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit FundsAdded(msg.sender, token, amount);
    }

    // Function to add Ether funds
    function addEtherFunds() external payable onlyOwner {
        emit FundsAdded(msg.sender, address(0), msg.value);
    }

    function executeArbitrage(
        address[] calldata path, 
        uint amountIn, 
        uint amountOutMin, 
        uint deadline
    ) external onlyOwner nonReentrant {
        require(path.length > 1, "Path too short");
        
        IERC20 inputToken = IERC20(path[0]);
        inputToken.safeApprove(address(uniswapRouter), amountIn);

        uint[] memory amounts = uniswapRouter.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), deadline);
        emit ArbitrageExecuted(msg.sender, amounts[0], amounts[amounts.length - 1]);
    }

    // Function to withdraw tokens
    function withdrawFunds(address token, uint amount) external onlyOwner {
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    // Function to withdraw Ether
    function withdrawETH(uint amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
    }
}
