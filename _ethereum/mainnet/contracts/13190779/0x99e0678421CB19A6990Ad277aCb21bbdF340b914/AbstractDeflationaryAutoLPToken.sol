// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./AbstractDeflationaryToken.sol";


abstract contract AbstractDeflationaryAutoLPToken is AbstractDeflationaryToken {
   
    uint256 public _liquidityFee;

    address public liquidityOwner;
    address public immutable poolAddress;

    uint256 constant SWAP_AND_LIQUIFY_DISABLED = 0;
    uint256 constant SWAP_AND_LIQUIFY_ENABLED = 1;
    uint256 constant IN_SWAP_AND_LIQUIFY = 2;
    uint256 LiqStatus;

    uint256 private numTokensSellToAddToLiquidity;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event LiquidityOwnerChanged(address newLiquidityOwner);


    modifier lockTheSwap {
        LiqStatus = IN_SWAP_AND_LIQUIFY;
        _;
        LiqStatus = SWAP_AND_LIQUIFY_ENABLED;
    }

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
        address liquidityPoolAddress

        ) AbstractDeflationaryToken(
            tName,
            tSymbol,
            totalAmount,
            tDecimals,
            tTaxFee,
            maxTxAmount
        ) {
        _liquidityFee = tLiquidityFee;
        numTokensSellToAddToLiquidity = _numTokensSellToAddToLiquidity;

        if (_swapAndLiquifyEnabled) {
            LiqStatus = SWAP_AND_LIQUIFY_ENABLED;
        }

        liquidityOwner = _msgSender();
        poolAddress = liquidityPoolAddress;
    }

    receive() external virtual payable {}

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        _liquidityFee = liquidityFee;
    }

    function setNumTokensSellToAddToLiquidity(uint256 newNumTokensSellToAddToLiquidity) external onlyOwner {
        numTokensSellToAddToLiquidity = newNumTokensSellToAddToLiquidity;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        LiqStatus = _enabled ? 1 : 0;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setLiquidityOwner(address newLiquidityOwner) external onlyOwner {
        liquidityOwner = newLiquidityOwner;
        emit LiquidityOwnerChanged(newLiquidityOwner);
    }

    function _takeLiquidity(uint256 tLiquidity, uint256 rate) internal {
        if (tLiquidity == 0) return;
        
        if(_isExcludedFromReward[address(this)] == 1) {
            _tOwned[address(this)] += tLiquidity;
            _tIncludedInReward -= tLiquidity;
            _rIncludedInReward -= tLiquidity * rate;
        }
        else {
            _rOwned[address(this)] += tLiquidity * rate;
        }
    }
    function _getTransferAmount(uint256 tAmount, uint256 totalFeesForTx, uint256 rate) internal virtual override view 
    returns(uint256 tTransferAmount, uint256 rTransferAmount) {
        tTransferAmount = tAmount - totalFeesForTx;
        rTransferAmount = tTransferAmount * rate;
    }

    function _recalculateRewardPool(
        bool isSenderExcluded, 
        bool isRecipientExcluded,
        uint256[] memory fees,
        uint256 tAmount,
        uint256 rAmount,
        uint256 tTransferAmount,
        uint256 rTransferAmount) internal virtual override{

        if (isSenderExcluded) {
            if (isRecipientExcluded) {
                _tIncludedInReward += fees[0];
                _rIncludedInReward += fees[1];  
            } else {
                _tIncludedInReward += tAmount;
                _rIncludedInReward += rAmount;              
            }
        } else {
            if (isRecipientExcluded) {
                if (!isSenderExcluded) {
                    _tIncludedInReward -= tTransferAmount;
                    _rIncludedInReward -= rTransferAmount;
                }
            }
        }
    }

   
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount != 0, "Transfer amount can't be zero");

        address __owner = owner();
        if(from != __owner && to != __owner)
            require(amount <= _maxTxAmount, "Amount exceeds the maxTxAmount");


        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 _numTokensSellToAddToLiquidity = numTokensSellToAddToLiquidity; // gas savings
        if (
            balanceOf(address(this)) >= _numTokensSellToAddToLiquidity &&
            _maxTxAmount >= _numTokensSellToAddToLiquidity &&
            LiqStatus == SWAP_AND_LIQUIFY_ENABLED &&
            from != poolAddress
        ) {
            //add liquidity
            _swapAndLiquify(_numTokensSellToAddToLiquidity);
        }

        //if any account belongs to _isExcludedFromFee account then remove the fee
        bool takeFee = _isExcludedFromFee[from] == 0 && _isExcludedFromFee[to] == 0;

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee, false);
    }

    function _swapAndLiquify(uint256 contractTokenBalance) internal virtual;

    function _swapTokensForEth(uint256 tokenAmount) internal virtual;

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal virtual;
    
    function _getFeesArray(uint256 tAmount, uint256 rate, bool takeFee) internal view override virtual returns(uint256[] memory fees) {
        fees = new uint256[](5);
        if (takeFee) {
            // Holders fee
            fees[2] = tAmount * _taxHolderFee / 100; // t
            fees[3] = fees[2] * rate;                // r

            // liquidity fee
            fees[4] = tAmount * _liquidityFee / 100; // t

            // Total fees
            fees[0] = fees[2] + fees[4];             // t
            fees[1] = fees[3] + fees[4] * rate;      // r
        }
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee, bool ignoreBalance)
    internal override virtual {
            
        uint256 rate = _getRate();
        uint256 rAmount = amount * rate;
        uint256[] memory fees = _getFeesArray(amount, rate, takeFee);

        (uint256 tTransferAmount, uint256 rTransferAmount) = _getTransferAmount(amount, fees[0], rate);

        {
            bool isSenderExcluded = _isExcludedFromReward[sender] == 1;
            bool isRecipientExcluded = _isExcludedFromReward[recipient] == 1;

            if (isSenderExcluded) {
                _tOwned[sender] -= ignoreBalance ? 0 : amount;
            } else {
                _rOwned[sender] -= ignoreBalance ? 0 : rAmount;
            }

            if (isRecipientExcluded) {
                _tOwned[recipient] += tTransferAmount;
            } else {
                _rOwned[recipient] += rTransferAmount;
            }

            if (!ignoreBalance) _recalculateRewardPool( 
                isSenderExcluded, 
                isRecipientExcluded, 
                fees,
                amount, 
                rAmount,
                tTransferAmount,
                rTransferAmount);
        }

        _takeLiquidity(fees[4], rate);
        _reflectHolderFee(fees[2], fees[3]);
        emit Transfer(sender, recipient, tTransferAmount);
    }
}