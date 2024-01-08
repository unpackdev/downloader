// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./AbstractBurnableDeflToken.sol";
import "./FeeToAddr.sol";

contract MOM is FeeToAddrDeflAutoLPToken, AbstractBurnableDeflToken {
    constructor(
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
    ) FeeToAddrDeflAutoLPToken(
        tName,
        tSymbol,
        totalAmount,
        tDecimals,
        tTaxFee,
        tLiquidityFee,
        maxTxAmount,
        _numTokensSellToAddToLiquidity,
        _swapAndLiquifyEnabled,
        tUniswapV2Router) {
    }

    function totalSupply() external view override returns(uint256) {
        return _tTotal - totalBurned;
    }
}