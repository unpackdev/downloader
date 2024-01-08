// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract Emojilution is ERC20, Ownable {
    using SafeMath for uint256;

    bool startTrading = false;
    address uniswapPair;

    constructor() ERC20("Emojilution", "Emojilution") {
        IUniswapV2Router02 router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapPair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
        _mint(owner(), 1e4*1e18);
    }

    function _beforeTokenTransfer(address from, address to, uint256) override internal view {
        if(from != owner() && to != owner() && from == uniswapPair)
            require(startTrading, "Trading has not started");
    }

    function openTrading() external onlyOwner {
        startTrading = true;
    } 

    function addLiquidity() external onlyOwner {
        require(!startTrading, "Trading has already started");
        IUniswapV2Router02 router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(router), type(uint256).max);
        router.addLiquidityETH{ value: address(this).balance }(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
    }
    
    function recoverEth() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function recoverTokens(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(_msgSender(), token.balanceOf(address(this)));
    }

    receive() external payable {}
}