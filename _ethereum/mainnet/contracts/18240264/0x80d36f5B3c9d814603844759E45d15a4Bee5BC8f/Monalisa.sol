
pragma solidity ^0.8.0;

import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

import "./MonalisaState.sol";

contract Monalisa is MonalisaState {
    
    function initialize() initializer public {
        __MonalisaState_init();
        __Ownable_init();

        setExcludedFromFees(_msgSender(), true);
        setExcludedFromWhale(_msgSender(), true);
    }

    
    receive() external payable {}

    function _passAntiWhaleToSell(address seller, uint256 amount) internal returns(bool) {
        if (!_antiWhale.enabled || _isExcludedFromWhale[seller]) {
            return true;
        }

        
        if (amount < _antiWhale.minSellTxAmount || amount > _antiWhale.maxSellTxAmount) {
            return false;
        }

        
        if ((block.timestamp - _tAmountPerHour[seller]) >= _antiWhale.timeLimit) {
            _tAmountPerHour[seller] = block.timestamp;
            _rAmountPerHour[seller] = 0;
        }

        
        if ((_rAmountPerHour[seller] + amount) > _antiWhale.maxPerHourTxAmount) {
            return false;
        }

        
        (uint tokenLiquidity, uint wethLiquidity, ) = IUniswapV2Pair(pairAddress).getReserves();
        uint ethForTokens = IUniswapV2Router02(routerAddress).getAmountOut(amount, tokenLiquidity, wethLiquidity);

        if (ethForTokens >= wethLiquidity * _antiWhale.maxOverLiquidityLimit / (100*_percent)) {
            return false;
        }

        _rAmountPerHour[seller] = _rAmountPerHour[seller] + amount;

        return true;
    }

    function _passAntiWhaleToTransfer(address from, address to, uint256 amount) internal returns(bool) {
        if (!_antiWhale.enabled || _isExcludedFromWhale[from] || _isExcludedFromWhale[to]) {
            return true;
        }

        if (amount <= _antiWhale.maxTransferLimit) {
            if ((block.timestamp - _tAmountPerHour[from]) >= _antiWhale.timeLimit) {
                _tAmountPerHour[from] = block.timestamp;
                _rAmountPerHour[from] = 0;
            }

            if ((_rAmountPerHour[from] + amount) <= _antiWhale.maxPerHourTxAmount) {
                _rAmountPerHour[from] = _rAmountPerHour[from] + amount;
                _rAmountPerHour[to] = _rAmountPerHour[to] + amount;

                return true;
            }
        }

        return false;
    }

    
    function withdraw(address receiver) external onlyOwner {
        payable(receiver).transfer(address(this).balance);
    }

    
    function withdrawTokens(address receiver, uint amount) public onlyOwner {
        _transferTokens(address(this), receiver, amount);
    }

    /* Claims */
    function setClaimData(uint32 claimStart, uint32 claimPeriod, uint8 claimCountTotal) public onlyOwner {
        _claimStart = claimStart;
        _claimPeriod = claimPeriod;
        _claimCountTotal = claimCountTotal;
    }

    
    function getClaimData(address account) public view returns(ClaimData memory) {
        return _claims[account];
    }

    
    function claim() public nonReentrant {
        address account = _msgSender();

        require(block.timestamp >= _claimStart, "Claim: not started");
        require(!isExcludedFromSwapAndTransfer(account), "isExcludedFromSwapAndTransfer: you are excluded from operations with MONALISA.");

        uint32 claims = _claims[account].claims;
        uint claimed = _claims[account].claimed;
        uint allocation = _claims[account].allocation;

        uint allocationLeft = allocation - claimed;
        uint32 claimsFromUnlock = uint32((block.timestamp - _claimStart + _claimPeriod) / _claimPeriod);

        if (claimsFromUnlock > _claimCountTotal) {
            claimsFromUnlock = _claimCountTotal;
        }

        uint32 availableClaims = claimsFromUnlock - claims;
        uint32 totalClaims = _claimCountTotal - claims;

        require(availableClaims > 0, "Claim: no claims left");

        uint amountToClaim = (allocationLeft / totalClaims) * availableClaims;

        require(amountToClaim > 0, "Claim: nothing to claim");

        _claims[account].claims = claimsFromUnlock;
        _claims[account].claimed += amountToClaim;

        _transferTokens(address(this), account, amountToClaim);
    }


    
    function addToClaimList(ClaimParticipant[] calldata list) public onlyOwner {
        uint totalAmount = 0;

        for (uint8 i = 0; i < list.length; i++) {
            address wallet = list[i].wallet;

            _claimsList.push(wallet);

            _claims[wallet].wallet = wallet;
            _claims[wallet].allocation = list[i].allocation;

            totalAmount += _claims[wallet].allocation - _claims[wallet].claimed;
        }

        
        _transferTokens(_msgSender(), address(this), totalAmount);
    }

    function getClaimsLeft() public view returns(uint) {
        uint total = 0;

        for (uint8 i = 0; i < _claimsList.length; i++) {
            ClaimData memory data = _claims[_claimsList[i]];

            total += (data.allocation - data.claimed);
        }

        return total;
    }

    /* Transfers */
    function _transfer(address from, address to, uint256 amount) internal virtual override {
        address sender = _msgSender(); 

        require(!isExcludedFromSwapAndTransfer(sender) && !isExcludedFromSwapAndTransfer(to), "isExcludedFromSwapAndTransfer: you are excluded from operations with token.");

        bool isPairAddressInvolved = (from == pairAddress || to == pairAddress);
        bool excludedFromFee = isExcludedFromFee(sender) || isExcludedFromFee(to) || isExcludedFromFee(from);
        bool internalTransfer = _inSwap || _inLiquidity;
        bool takeFees = !internalTransfer && isPairAddressInvolved && !excludedFromFee;

        
        if (takeFees) {
            _inSwap = true;

            uint feeAmount = 0;

            
            if (from == pairAddress) {
                feeAmount = amount * _feesAndTaxes.buyFee / (100 * _percent);
            }
            
            else if (to == pairAddress) {
                require(_passAntiWhaleToSell(from, amount), "AntiWhaleSystem: You are not passed anti-whale");

                feeAmount = amount * _feesAndTaxes.sellFee / (100 * _percent);
            }

            uint liqAmount = amount * _feesAndTaxes.liquidityTax / (100 * _percent);
            uint amountToBuyer = amount - (feeAmount + liqAmount);

            
            _transferTokens(from, to, amountToBuyer);
            _transferTokens(from, marketing, feeAmount);

            
            _transferTokens(from, address(this), liqAmount);
            liquidityCapital += liqAmount;

            if (liquidityCapital >= liquidityCapitalLimit) {
                _swapAndLiquify(liquidityCapital);
                liquidityCapital = 0;
            }

            _inSwap = false;
        }
        else {
            if(!internalTransfer){
                require(_passAntiWhaleToTransfer(from, to, amount), "AntiWhaleSystem: You are not passed anti-whale");
            }
            _transferTokens(from, to, amount);
        }
    }

    function _transferTokens(address from, address to, uint256 amount) internal virtual {
        super._transfer(from, to, amount);
    }

    function withdrawLiquidity() public onlyAdmin {
        _swapAndLiquify(liquidityCapital);

        liquidityCapital = 0;
    }

    
    function _swapAndLiquify(uint tokenAmount) internal {
        require(tokenAmount > 0 && tokenAmount <= balanceOf(address(this)), "Not enough tokens in the contract");

        
        uint256 tokensForSwap = tokenAmount * liquidityShareETH / (100 * _percent);
        uint256 tokensForLiq = tokenAmount - tokensForSwap;

        _inLiquidity = true;

        if (tokensForLiq > 0 && tokensForSwap > 0) {
            uint initialBalance = address(this).balance;

            
            _swapTokensForEth(tokensForSwap);

            uint newBalance = address(this).balance - initialBalance;

            
             _addLiquidity(tokensForLiq, newBalance);
        }

        _inLiquidity = false;
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);

        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = wethAddress;

        _approve(address(this), routerAddress, tokenAmount);

        
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);

        
        _approve(address(this), routerAddress, tokenAmount);

        
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, 
            0, 
            liquidityPool,
            block.timestamp + 600
        );
    }

    
    function updateRouter(address newRouterAddress) public onlyOwner returns(address) {
        require(newRouterAddress != address(routerAddress), "The router already has that address");

        IUniswapV2Router02 router = IUniswapV2Router02(newRouterAddress);

        address newWethAddress = router.WETH();
        address newPairAddress = IUniswapV2Factory(router.factory()).getPair(address(this), newWethAddress);

        
        if (newPairAddress == zeroAddress) {
            newPairAddress = IUniswapV2Factory(router.factory()).createPair(address(this), newWethAddress);
        }

        pairAddress = newPairAddress;
        routerAddress = newRouterAddress;
        wethAddress = newWethAddress;

        return newPairAddress;
    }
}

