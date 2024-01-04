// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./Context.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./Constants.sol";
import "./XST.sol";

contract Liquidity is Context, Ownable {
    using SafeMath for uint256;
    using Address for address;
    XStable token;
    IUniswapV2Router02 public uniswapRouterV2;
    IUniswapV2Factory public uniswapFactory;

    modifier sendTaxless {
        token.setTaxless(true);
        _;
        token.setTaxless(false);
    }
    constructor (address tokenAdd) public {
        token = XStable(tokenAdd);
        uniswapRouterV2 = IUniswapV2Router02(Constants.getRouterAdd());
        uniswapFactory = IUniswapV2Factory(Constants.getFactoryAdd());
    }
    function addLiquidityETHOnly() external payable sendTaxless {
        require(msg.value > 0, "Need to provide eth for liquidity");
        address tokenUniswapPair = uniswapFactory.getPair(address(token),uniswapRouterV2.WETH());
        uint256 initialBalance = address(this).balance.sub(msg.value);
        uint256 initialTokenBalance = token.balanceOf(address(this));
        uint256 amountToSwap = msg.value.div(2);
        address[] memory path = new address[](2);
        path[0] = uniswapRouterV2.WETH();
        path[1] = address(token);
        uniswapRouterV2.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountToSwap}(0,path,address(this),block.timestamp);
        uint256 newTokenBalance = token.balanceOf(address(this)).sub(initialTokenBalance);
        token.approve(address(uniswapRouterV2),newTokenBalance);
        uniswapRouterV2.addLiquidityETH{value: amountToSwap}(address(token),newTokenBalance,0,0,_msgSender(),block.timestamp);
        uint256 excessTokens = token.balanceOf(address(this)).sub(initialTokenBalance);
        token.silentSyncPair(tokenUniswapPair);
        if (excessTokens >0) {
            token.transfer(_msgSender(),excessTokens);
        }
        uint256 dustEth = address(this).balance.sub(initialBalance);
        if (dustEth>0) _msgSender().transfer(dustEth);
    }
}