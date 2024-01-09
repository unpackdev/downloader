// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./ITenSetToken.sol";


contract Swapper is Ownable {

    using Address for address payable;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public token;
    address payable public feeWallet;
    uint256 public swapFee;
    uint256 public minAmount;

    IUniswapV2Router02 public uniswapV2Router;

    event SwapStarted(address indexed tokenAddr, address indexed fromAddr, uint256 amount);
    event SwapFinalized(address indexed tokenAddr, address indexed toAddress, uint256 amount);
    event SwapTokensForETH(uint256 tokenAmount, address[] indexed path);

    constructor(address payable _feeWallet) {
        feeWallet = _feeWallet;
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    function setSwapFee(uint256 fee) onlyOwner external {
        swapFee = fee;
    }

    function setMinAmount(uint256 newMinAmount) onlyOwner external {
        minAmount = newMinAmount;
    }

    function setFeeWallet(address payable newWallet) onlyOwner external {
        feeWallet = newWallet;
    }

    function setToken(address newToken) onlyOwner external returns (bool) {
        token = newToken;
        return true;
    }

    function finalizeSwap(address toAddress, uint256 amount) onlyOwner external returns (bool) {
        IERC20(token).safeTransfer(toAddress, amount);
        emit SwapFinalized(token, toAddress, amount);
        return true;
    }

    function startSwap(uint256 amount) external returns (bool) {
        require(amount >= minAmount, "amount is too small");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        swapTokensForEth(minAmount);
        emit SwapStarted(token, msg.sender, amount.sub(minAmount));
        return true;
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniswapV2Router.WETH();
    
        IERC20(token).approve(address(uniswapV2Router), tokenAmount);
    
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
          tokenAmount,
          0, // accept any amount of ETH
          path,
          feeWallet, // The contract
          block.timestamp
        );
    
        emit SwapTokensForETH(tokenAmount, path);
    }
}