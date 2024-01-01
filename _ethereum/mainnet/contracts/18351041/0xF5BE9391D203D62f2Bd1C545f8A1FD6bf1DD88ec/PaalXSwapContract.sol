// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import "./IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./SafeERC20.sol";

contract PaalXSwapContract is Context, Ownable {

    using SafeERC20 for IERC20;

    // Uniswap v2 Router
    IUniswapV2Router02 immutable router;

    // Set swapping fee to 10000 / 1000000 = 1%
    uint24 public swappingFee = 10000;

    // Buy Event
    event Buy(address indexed buyer, uint256 amountEthIn, address indexed tokenToBuy, uint256 amountTokenOut);

    // Sell Event
    event Sell(address indexed seller, address indexed token, uint256 amountTokenIn, uint256 amountEthOut);

    constructor(IUniswapV2Router02 _router) {
        router = _router;
    }

    function buy(address tokenAddr, uint256 amountOutMin)
        external
        payable
        returns (uint256 amountOut)
    {
        require(tokenAddr != address(0), "Invalid token address");
        require(msg.value > 0, "Invalid amount");

        IERC20 token = IERC20(tokenAddr);
        IERC20 weth = IERC20(router.WETH());
        address sender = _msgSender();

        uint256 fee = (msg.value * swappingFee) / 1000000;
        uint256 amountIn = msg.value - fee;

        weth.approve(address(router), amountIn);

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = tokenAddr;

        uint256 beforeBalance = token.balanceOf(sender);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amountIn
        }(amountOutMin, path, sender, block.timestamp + 300);
        uint256 afterBalance = token.balanceOf(sender);

        amountOut = afterBalance - beforeBalance;

        emit Buy(sender, msg.value, tokenAddr, amountOut);
    }

    function sell(
        address tokenAddr,
        uint256 amountIn,
        uint256 amountOutMin
    ) external returns (uint256 amountOut) {
        require(tokenAddr != address(0), "Invalid token address");
        require(amountIn > 0, "Invalid input amount");

        IERC20 token = IERC20(tokenAddr);
        address sender = _msgSender();

        // Record the contract's initial balance
        uint256 initialBalance = token.balanceOf(address(this));

        // Transfer the tokens from the sender to this contract
        token.safeTransferFrom(sender, address(this), amountIn);

        // Calculate the actual tokens received after any fee-on-transfer
        uint256 actualReceived = token.balanceOf(address(this)) - initialBalance;

        // Calculate the swapping fee and the transaction amount
        uint256 fee = (actualReceived * swappingFee) / 1000000;
        uint256 txAmount = actualReceived - fee;

        // Approve the router to spend the tokens for the swap
        token.safeApprove(address(router), txAmount);

        address[] memory path = new address[](2);
        path[0] = tokenAddr;
        path[1] = router.WETH();

        uint256 beforeBalance = sender.balance;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            txAmount,
            amountOutMin,
            path,
            sender,
            block.timestamp + 300
        );
        uint256 afterBalance = sender.balance;

        amountOut = afterBalance - beforeBalance;

        emit Sell(sender, tokenAddr, amountIn, amountOut);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawToken(address tokenAddress, address to)
        external
        onlyOwner
        returns (bool res)
    {
        IERC20 token = IERC20(tokenAddress);
        res = token.transfer(to, token.balanceOf(address(this)));
    }

    function setSwappingFee(uint24 fee) external onlyOwner {
        swappingFee = fee;
    }
}
