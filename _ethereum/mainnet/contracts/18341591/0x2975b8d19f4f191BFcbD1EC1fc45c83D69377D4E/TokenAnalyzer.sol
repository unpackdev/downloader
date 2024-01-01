// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IUniswapV2Router {
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable returns (uint256[] memory amounts);
    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
    function WETH() external pure returns (address);
}

contract TokenAnalyzer {
    IUniswapV2Router public uniswapV2Router;
    address public owner;

    constructor(address _uniswapV2Router) {
        uniswapV2Router = IUniswapV2Router(_uniswapV2Router);
        owner = msg.sender;  // Set the contract deployer as the owner
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    function analyzeToken(address tokenAddress) external payable returns (bool isHoneypot, uint256 buyTax, uint256 sellTax) {
        address wethAddress = uniswapV2Router.WETH();

        address[] memory path = new address[](2);
        path[0] = wethAddress;
        path[1] = tokenAddress;

        uint256[] memory amountsOutBuy;
        uint256[] memory amountsOutSell;

        // Estimate tokens to be received
        uint256[] memory estimatedTokens = uniswapV2Router.getAmountsOut(msg.value, path);
        uint256 estimatedTokensReceived = estimatedTokens[1];

        // Try simulating a buy
        try uniswapV2Router.swapExactETHForTokens{value: msg.value}(0, path, address(this), block.timestamp + 15) returns (uint256[] memory result) {
            amountsOutBuy = result;
        } catch {
            isHoneypot = true;
            return (isHoneypot, 0, 0);
        }

        uint256 actualTokensReceived = amountsOutBuy[1];
        buyTax = ((estimatedTokensReceived - actualTokensReceived) * 1000) / estimatedTokensReceived;  // Calculating buyTax based on estimated and actual tokens received

        path[0] = tokenAddress;
        path[1] = wethAddress;

        // Reset approve
        IERC20(tokenAddress).approve(address(uniswapV2Router), 0);
        IERC20(tokenAddress).approve(address(uniswapV2Router), actualTokensReceived);

        // Estimate ETH to be received
        uint256[] memory estimatedEth = uniswapV2Router.getAmountsOut(actualTokensReceived, path);
        uint256 estimatedEthReceived = estimatedEth[1];

        // Try simulating a sell
        try uniswapV2Router.swapExactTokensForETH(actualTokensReceived, 0, path, address(this), block.timestamp + 15) returns (uint256[] memory result) {
            amountsOutSell = result;
        } catch {
            isHoneypot = true;
            return (isHoneypot, buyTax, 0);
        }

        uint256 actualEthReceived = amountsOutSell[1];
        sellTax = ((estimatedEthReceived - actualEthReceived) * 1000) / estimatedEthReceived;  // Calculating sellTax based on estimated and actual ETH received

        if (actualTokensReceived == 0 || actualEthReceived == 0) {
            isHoneypot = true;
        }

        return (isHoneypot, buyTax, sellTax);
    }

    // Function to withdraw ETH from the contract
    function withdrawETH(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        payable(owner).transfer(amount);
    }

    // Fallback function to accept ETH
    fallback() external payable {
    }

    // Receive function to accept ETH
    receive() external payable {
    }

}