// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Address.sol";
import "./Ownable.sol";

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";

import "./ERC20.sol";

contract LPBasic is Ownable, ERC20 {
		using Address for address;

		address payable internal _devWallet;
		function setDevWallet(address payable devwallet) public onlyOwner { _devWallet = devwallet; }

		/* --- rate configuration --- */

		uint256 internal constant _rateDivisor =  1000000;  // rate at this value = 100%

		uint256 internal _lpRateA  =      150000;
		uint256 internal _lpRateB  =       50000;
		uint256 internal _lpRateC  =       25000;

		uint256 internal _lpTierA  = 5 * (10 ** 18);
		uint256 internal _lpTierB  = 20 * (10 ** 18);
		uint256 internal _lpTierC  = 100 * (10 ** 18);

		uint256 internal _lpPendingBalance;
		function pendingBalanceLP() public view returns(uint256) { return _lpPendingBalance; }
		
		uint256 internal _lpPendingThrottle = 250000 * (10 ** 18); // while LP ETH < 20ETH - MAX PUSH TO LP
		
		
		uint256 internal _txMaximum = 500000; // maximum tx size in % of current pool

		uint256 internal _walletMax = 1000000 * (10 ** 18); // while LP ETH < 20ETH - WALLET LIMIT
		uint256 internal _walletMaxTier = 20 * (10 ** 18);

		uint256 internal _devRate  =       15000;

		uint256 internal _devPendingBalance;
		function pendingBalanceDev() public view returns(uint256) { return _devPendingBalance; }

		bool _feePendingAlternate;
		uint256 internal _feePendingThreshold = 1 * (10 ** 16); // 0.01 ETH
		
		

		/* --- current state - once top tier is exited permanently inactive --- */

		bool internal _lpRateActive = true;
		bool internal _lpLimitActive = true;

		bool internal _tradingEnabled = false;
		function setTradingEnabled() public onlyOwner { _tradingEnabled = true; }
		


		/* --- uniswap v2 - router and pair configurable - no fees will be charged until pair is set --- */

		address _uniswapFactoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
		address _uniswapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
		function setRouterAddress(address routeraddress) public onlyOwner { _uniswapRouterAddress = routeraddress; }
		address internal _uniswapPairAddress;
		function setPairAddress(address pairaddress) public onlyOwner { _uniswapPairAddress = pairaddress; }
		function getPairAddress() public view returns(address) { return _uniswapPairAddress; }

		address internal _tokenAddressWETH;
		
		
		bool _locked;
    modifier locked() {
        require(!_locked,"LPBasic: Blocked reentrant call.");
        _locked = true;
        _;
        _locked = false;
    }


		constructor(string memory name, string memory symbol, uint256 supply) ERC20(name, symbol) {
				_mint(address(this),supply);
				_tokenAddressWETH = IUniswapV2Router02(_uniswapRouterAddress).WETH();
		}


		/* --- transfer functions --- */

		function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
				_transfer(_msgSender(), recipient, amount);
				return true;
		}

		function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
				_transfer(sender, recipient, amount);
				uint256 currentAllowance = _allowances[sender][_msgSender()];
				require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
				unchecked {
						_approve(sender, _msgSender(), currentAllowance - amount);
				}
				return true;
		}

		function _transfer( address sender, address recipient, uint256 amount ) internal virtual override {

				require(sender != address(0), "ERC20: transfer from the zero address");
				require(recipient != address(0), "ERC20: transfer to the zero address");
				require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");

				(bool isTaxed, bool isSell, uint256 lpToken, uint256 lpEth) = _isTaxed(sender,recipient);
				if(isTaxed) require(amount < _transferMaximum(lpToken,lpEth),"LPBasic: amount exceeds maximum allowed");

				if(isTaxed) {
						require(_tradingEnabled, "LPBasic: trading has not been enabled");
						_transferTaxed(sender,recipient,amount,lpToken,lpEth,isSell);
				}
				else _transferUntaxed(sender,recipient,amount);

		}
		
		function _transferMaximum(uint256 lpToken, uint256 lpEth) internal view returns(uint256 transferMax) {
				if(!_lpLimitActive) return _totalSupply;
				else transferMax = _txMaximum * lpToken / _rateDivisor;
		}

		function _isTaxed(address sender, address recipient) internal returns(bool isTaxed,bool isSell,uint256 tokenReserves,uint256 ethReserves) {

				if(sender==address(this) || recipient==address(this)) return (false,false,0,0);

				if((sender == _uniswapPairAddress && recipient == _uniswapRouterAddress)
						|| (recipient == _uniswapPairAddress && sender == _uniswapRouterAddress))
						return (false,false,0,0);

				if(_uniswapPairAddress==address(0)) return (false,false,0,0);

				bool isBuy = sender==_uniswapRouterAddress || sender==_uniswapPairAddress;
				isSell = recipient==_uniswapRouterAddress || recipient==_uniswapPairAddress;

				isTaxed = isBuy || isSell;

				if(isTaxed) {
						(tokenReserves,ethReserves) = _getReserves();

						if(_lpLimitActive && ethReserves > _walletMaxTier) _lpLimitActive = false;

						// one way switch disabled - lp fee can turn back on when eth balance returns to tier c
						//if(_lpRateActive && ethReserves > _lpTierC) _lpRateActive = false;
				}
		}
		
		function _getReserves() internal returns(uint256 tokenReserves,uint256 ethReserves) {
				(uint256 reserve0,uint256 reserve1,) = IUniswapV2Pair(_uniswapPairAddress).getReserves();
				if(IUniswapV2Pair(_uniswapPairAddress).token0()==address(this)) {
						tokenReserves = reserve0;
						ethReserves = reserve1;
				} else {
						ethReserves = reserve0;
						tokenReserves = reserve1;
				}
		}

		function _transferUntaxed( address sender, address recipient, uint256 amount ) internal {
				_beforeTokenTransfer(sender, recipient, amount);
				_balances[sender] -= amount;
				_balances[recipient] += amount;
				emit Transfer(sender, recipient, amount);
				_afterTokenTransfer(sender, recipient, amount);
		}

		function _lpTaxRate(uint256 ethBalance) internal view returns(uint256 _taxRate) {
				if(_lpRateActive) {
						if(ethBalance < _lpTierA) { _taxRate = _lpRateA; }
						else if(ethBalance < _lpTierB) { _taxRate = _lpRateB; }
						else if(ethBalance < _lpTierC) { _taxRate = _lpRateC; }
						else { _taxRate = 0; }
				}
		}

		function _transferTaxed( address sender, address recipient, uint256 amount, uint256 lpTokenBalance, uint256 lpEthBalance, bool isSell ) internal {
				
				if(isSell) {
						bool pendingDevReady = (_devPendingBalance * lpEthBalance / lpTokenBalance) > _feePendingThreshold;
						bool pendingLpReady = (_lpPendingBalance * lpEthBalance / lpTokenBalance) > _feePendingThreshold;
						bool pendingReady = pendingDevReady || pendingLpReady;
						if(!_locked && isSell && pendingReady) {
								if(!pendingLpReady || (_feePendingAlternate && pendingDevReady)) {
										_convertTaxDev();
										_feePendingAlternate = false;
								}
								else {
										_processTaxLP(lpTokenBalance,lpEthBalance);
										_feePendingAlternate = true;
								}
						}
				}

				uint256 taxRate = _lpTaxRate(lpEthBalance);
				
				uint256 taxAmount = (taxRate>0 ? amount * taxRate / _rateDivisor : 0);
				uint256 devAmount = amount * _devRate / _rateDivisor;

				_balances[sender] -= amount;

				uint256 recAmount = amount - (taxAmount + devAmount);

				if(!isSell && _lpLimitActive && (_balances[recipient] + recAmount) > _walletMax) {
						uint256 overMax = (_balances[recipient] > _walletMax ? recAmount : _balances[recipient] + recAmount - _walletMax);
						recAmount -= overMax;
						taxAmount += overMax;
				}

				if(recAmount>0) {
						_balances[recipient] += recAmount;
						emit Transfer(sender, recipient, recAmount);
				}
				if(taxAmount>0) {
						_balances[address(this)] += taxAmount;
						_lpPendingBalance += taxAmount;
						emit Transfer(sender, address(this), taxAmount);
				}
				if(devAmount>0) {
						_balances[address(this)] += devAmount;
						_devPendingBalance += devAmount;
						emit Transfer(sender, address(this), devAmount);
				}
		}

		function _convertTaxDev() internal locked {
				(uint256 tokenDelta,) = _swapTokensForEth(_devPendingBalance, _devWallet);
				_devPendingBalance -= tokenDelta;
		}

		function _processTaxLP(uint256 poolTokenBalance, uint256 poolEthBalance) internal locked {
				
				uint256 ethBalance = address(this).balance;
				uint256 ethBalanceValue = (ethBalance * poolTokenBalance) / poolEthBalance;
				uint256 ethDelta;
				uint256 tokenDelta;
				
				uint256 lpPendingThreshold = pendingThreshold(poolTokenBalance,poolEthBalance);
				
				uint256 pendingAmount = ( (_lpPendingBalance>lpPendingThreshold) ? lpPendingThreshold : _lpPendingBalance );
				if(ethBalanceValue<pendingAmount) {
						uint256 ethConvert = ((pendingAmount + ethBalanceValue) / 2) - ethBalanceValue;
						(tokenDelta,ethDelta) = _swapTokensForEth(ethConvert,address(this));
				}
				(uint256 tokenDeposit,) = _addLiquidity(pendingAmount-tokenDelta,ethDelta+ethBalance);
				_lpPendingBalance -= (tokenDelta + tokenDeposit);
		}
		
		function pendingThreshold(uint256 poolTokenBalance,uint256 poolEthBalance) internal returns(uint256 threshold) {
				if( poolTokenBalance < _balances[address(this)] && poolEthBalance < (20 * (10 ** 18)) && poolEthBalance > (5 * (10 ** 18)) )
						threshold = ( ( (_lpPendingThrottle * 2) > ( (poolTokenBalance * 5) / 100 )) ? _lpPendingThrottle * 2 : ( (poolTokenBalance * 5) / 100 ) );
				else if(poolEthBalance < (5 * (10 ** 18)) ) threshold = _lpPendingThrottle;
				else if(poolEthBalance > (20 * (10 ** 18)) ) threshold = poolTokenBalance / 100;
				else threshold = ( ( _lpPendingThrottle < ( poolTokenBalance / 100 )) ? _lpPendingThrottle : ( poolTokenBalance / 100 ) );
		}



		function _swapTokensForEth(uint256 tokenAmount, address destination) internal returns(uint256 tokenDelta, uint256 ethDelta) {

				(uint256 tokenReserve, uint256 ethReserve) = _getReserves();

				_approve(address(this), _uniswapRouterAddress, tokenAmount);

				address[] memory path = new address[](2);
				path[0] = address(this);
				path[1] = _tokenAddressWETH;


				IUniswapV2Router02(_uniswapRouterAddress).swapExactTokensForETHSupportingFeeOnTransferTokens(
						tokenAmount,
						0,
						path,
						destination,
						block.timestamp + 100
				);
				(uint256 tokenReserveAfter, uint256 ethReserveAfter) = _getReserves();

				tokenDelta = uint256(tokenReserveAfter-tokenReserve);
				ethDelta = uint256(ethReserve-ethReserveAfter);
		}

		function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal returns(uint256 tokenDeposit,uint256 ethDeposit) {
				_approve(address(this), _uniswapRouterAddress, tokenAmount);
				(tokenDeposit, ethDeposit,) = IUniswapV2Router02(_uniswapRouterAddress).addLiquidityETH{value:ethAmount}(
						address(this),
						tokenAmount,
						0,
						0,
						address(this),
						block.timestamp + 100
				);
		}

		function initializeLiquidityPool() public payable onlyOwner {
				require(_uniswapPairAddress==address(0),"Pair address already set");
				IUniswapV2Factory _factory = IUniswapV2Factory(_uniswapFactoryAddress);
				_factory.createPair(address(this),_tokenAddressWETH);
				_uniswapPairAddress = _factory.getPair(address(this),_tokenAddressWETH);
				_addLiquidity(_balances[address(this)], msg.value);
		}




		receive() external payable {}





}