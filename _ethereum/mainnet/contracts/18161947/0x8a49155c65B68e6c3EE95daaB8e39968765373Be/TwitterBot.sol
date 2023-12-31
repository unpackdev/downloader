// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "./IERC20.sol";
import "./IUniswapV2Router02.sol";

contract TwitterBot {
    IUniswapV2Router02 private immutable v2Router;
    address private immutable WETH;
    address private owner;

    uint256 private teamFee = 5;
    uint256 private constant denominator = 1000;

    error EthTransferFailed();
    error notOwner();
    error TransferFailed();
    error ApprovalFailed();

    event Buy(address indexed user, address indexed tokenAddress, uint256 amountIn, uint256 amountOut);
    event Sell(address indexed user, address indexed tokenAddress, uint256 amountIn, uint256 amountOut);

    modifier onlyOwner() {
        if (msg.sender != owner) revert notOwner();
        _;
    }

    constructor() {
        v2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = v2Router.WETH();
    }

    function buyTokens_v2Router(address tokenAddress, uint256 amountOutMin) external payable {
        uint256 amountIn = msg.value * (denominator - teamFee) / denominator;

        uint256 initialBalance = IERC20(tokenAddress).balanceOf(msg.sender);
        // amountOutMin must be retrieved from an oracle of some kind
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = tokenAddress;
        v2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountIn}(
            amountOutMin, path, msg.sender, block.timestamp
        );

        emit Buy(msg.sender, tokenAddress, amountIn, IERC20(tokenAddress).balanceOf(msg.sender) - initialBalance);
    }

    function sellTokens_v2Router(address tokenAddress, uint256 amountIn, uint256 amountOutMin) external {
        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), amountIn);
        if (token.allowance(address(this), address(v2Router)) != type(uint256).max) {
            token.approve(address(v2Router), type(uint256).max);
        }

        uint256 initialBalance = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = WETH;
        v2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountIn, amountOutMin, path, address(this), block.timestamp
        );

        // 0.5% fee
        uint256 amountOut = (address(this).balance - initialBalance) * (denominator - teamFee) / denominator;
        (bool success,) = msg.sender.call{value: amountOut}("");
        if (!success) revert EthTransferFailed();

        emit Sell(msg.sender, tokenAddress, amountIn, amountOut);
    }

    function withdraw() external payable onlyOwner {
        (bool success,) = payable(owner).call{value: address(this).balance}("");
        if (!success) revert EthTransferFailed();
    }

    function changeOwner() external payable onlyOwner {
        owner = msg.sender;
    }

    receive() external payable {}
}
