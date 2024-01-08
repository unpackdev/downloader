// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./IBuyBack.sol";
import "./AuthorizedList.sol";
import "./LockableSwap.sol";

contract DynamicsBuyBack is AuthorizedList, LockableSwap, IBuyBack {
    using SafeMath for uint256;
    using Address for address;
    address public tokenAddress;
    address public injectorContract;

    uint256 public minBuyBack = 0.01 ether;
    uint256 public maxBuyBack = 2 ether;

    event UpdateRouter(address indexed newAddress, address indexed oldAddress);

    IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public uniswapV2Pair;

    constructor(address token, address _injectorContract) payable {
        authorizedCaller[token] = true;
        authorizedCaller[_msgSender()] = true;
        injectorContract = _injectorContract;
        tokenAddress = token;
        uniswapV2Pair = address(IUniswapV2Factory(uniswapV2Router.factory()).getPair(token, uniswapV2Router.WETH()));
    }

    receive() external payable {}

    fallback() external payable {}

    function buyBackTokens() external override {
        require(_msgSender() == address(tokenAddress), "Only callable by token contract");
        if(address(this).balance > minBuyBack){
            uint256 spendAmount = address(this).balance;
            if(spendAmount > maxBuyBack)
                spendAmount = maxBuyBack;
            if(!inSwapAndLiquify)
                _buyBackTokens(spendAmount, injectorContract);
        }
    }

    function swapETHForTokens(uint256 amount) private {
        // generate the uniswap pair path of token <- weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(tokenAddress);
        if(amount > address(this).balance){
            amount = address(this).balance;
        }

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(0, path, address(this), block.timestamp.add(400));
    }

    function buybackForce(uint256 amount) external authorized {
        require(amount <= address(this).balance, "Balance too low for this transaction");
        if(!inSwapAndLiquify)
            _buyBackTokens(amount, injectorContract);
    }

    function _buyBackTokens(uint256 amount, address destination) private lockTheSwap {

        swapETHForTokens(amount);
        try IERC20(tokenAddress).transfer(destination, IERC20(tokenAddress).balanceOf(address(this))) {} catch {}

        emit BuyBackTriggered(amount);
    }

    function updateRouter(address newAddress) public authorized {
        require(newAddress != address(uniswapV2Router), "The router already has that address");
        emit UpdateRouter(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function updateBuybackMinMax(uint256 min, uint256 max) external authorized {
        require(min < max, "Max value must be higher than minimum");
        minBuyBack = min;
        maxBuyBack = max;
    }
}
