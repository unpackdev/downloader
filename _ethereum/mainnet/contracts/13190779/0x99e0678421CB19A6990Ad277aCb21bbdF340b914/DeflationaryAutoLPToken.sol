// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./AbstractDeflationaryToken.sol";
import "./AbstractDeflationaryAutoLPToken.sol";


contract DeflationaryAutoLPToken is AbstractDeflationaryAutoLPToken {

    IUniswapV2Router02 public immutable uniswapV2Router;
    address private immutable WETH;

    constructor ( 
        string memory tName, 
        string memory tSymbol, 
        uint256 totalAmount,
        uint256 tDecimals, 
        uint256 tTaxFee, 
        uint256 tLiquidityFee,
        uint256 maxTxAmount,
        uint256 _numTokensSellToAddToLiquidity,
        bool _swapAndLiquifyEnabled,

        address tUniswapV2Router
        ) AbstractDeflationaryAutoLPToken (
            tName,
            tSymbol,
            totalAmount,
            tDecimals,
            tTaxFee,
            tLiquidityFee,
            maxTxAmount,
            _numTokensSellToAddToLiquidity,
            _swapAndLiquifyEnabled,
            IUniswapV2Factory(IUniswapV2Router02(tUniswapV2Router).factory())
                .createPair(address(this), IUniswapV2Router02(tUniswapV2Router).WETH()) // Create a uniswap pair for this new token
        ) {

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(tUniswapV2Router);
        uniswapV2Router = _uniswapV2Router;
        WETH = _uniswapV2Router.WETH();
    }

    function withdrawStuckFunds() external onlyOwner {
        // normally balance of contract always should be zero
        // but slippage in _addLiquidity is possible
        payable(owner()).transfer(address(this).balance);
    }

    function _swapAndLiquify(uint256 contractTokenBalance) internal override lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 currentBalance = address(this).balance;

        // swap tokens for ETH
        _swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        currentBalance = address(this).balance - currentBalance;

        // add liquidity to uniswap
        _addLiquidity(otherHalf, currentBalance);

        emit SwapAndLiquify(half, currentBalance, otherHalf);
    }

    function _swapTokensForEth(uint256 tokenAmount) internal override {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal override {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityOwner,
            block.timestamp
        );
    }
}