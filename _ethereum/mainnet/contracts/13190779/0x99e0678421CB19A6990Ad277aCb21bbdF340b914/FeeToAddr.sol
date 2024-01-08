// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./DeflationaryAutoLPToken.sol";
import "./FeeToAddress.sol";

contract FeeToAddrDeflAutoLPToken is DeflationaryAutoLPToken, FeeToAddress {
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
    ) DeflationaryAutoLPToken(
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

    function _getFeesArray(uint256 tAmount, uint256 rate, bool takeFee) 
    internal view override virtual returns(uint256[] memory fees) {
        fees = super._getFeesArray(tAmount, rate, takeFee);

        if (takeFee) {
            uint256 _feeSize = feeToAddress * tAmount / 100; // gas savings
            fees[0] += _feeSize; // increase totalFee
            fees[1] += _feeSize * rate; // increase totalFee reflections
        }
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee, bool ignoreBalance) internal override virtual {
        if (takeFee) {
            uint256 _feeSize = feeToAddress * amount / 100; // gas savings
            super._tokenTransfer(sender, feeBeneficiary, _feeSize, false, true); // cannot take fee - circular transfer
        }
        super._tokenTransfer(sender, recipient, amount, takeFee, ignoreBalance);
    }
}