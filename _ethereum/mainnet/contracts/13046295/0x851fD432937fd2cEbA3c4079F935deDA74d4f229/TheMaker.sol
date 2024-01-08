// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IUniswapV2Factory.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

//  TheMaker Token Summary
//  No fee, no tax
contract TheMaker is ERC20, Ownable {
    using SafeMath for uint256;

    bool private _startTrading = false;
    address private _uniswapPair;

    constructor() ERC20("The Maker", "$MAKER") {
        IUniswapV2Router02 router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _uniswapPair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
        _mint(owner(), 1e12*1e18);
    }

    function _beforeTokenTransfer(address from, address to, uint256) override internal view {
        if(from != owner() && to != owner() && from == _uniswapPair)
            require(_startTrading, "Trading has not started");
    }

    function openTrading() external onlyOwner {
        _startTrading = true;
    } 

    function addLiquidity() external onlyOwner {
        require(!_startTrading, "Trading has already started");
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