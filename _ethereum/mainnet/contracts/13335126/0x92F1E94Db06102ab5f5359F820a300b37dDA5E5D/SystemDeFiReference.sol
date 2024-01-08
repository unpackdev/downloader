// SPDX-License-Identifier: MIT
/*
░██████╗██╗░░░██╗░██████╗████████╗███████╗███╗░░░███╗  ██████╗░███████╗███████╗██╗  ███████╗░█████╗░██████╗░
██╔════╝╚██╗░██╔╝██╔════╝╚══██╔══╝██╔════╝████╗░████║  ██╔══██╗██╔════╝██╔════╝██║  ██╔════╝██╔══██╗██╔══██╗
╚█████╗░░╚████╔╝░╚█████╗░░░░██║░░░█████╗░░██╔████╔██║  ██║░░██║█████╗░░█████╗░░██║  █████╗░░██║░░██║██████╔╝
░╚═══██╗░░╚██╔╝░░░╚═══██╗░░░██║░░░██╔══╝░░██║╚██╔╝██║  ██║░░██║██╔══╝░░██╔══╝░░██║  ██╔══╝░░██║░░██║██╔══██╗
██████╔╝░░░██║░░░██████╔╝░░░██║░░░███████╗██║░╚═╝░██║  ██████╔╝███████╗██║░░░░░██║  ██║░░░░░╚█████╔╝██║░░██║
╚═════╝░░░░╚═╝░░░╚═════╝░░░░╚═╝░░░╚══════╝╚═╝░░░░░╚═╝  ╚═════╝░╚══════╝╚═╝░░░░░╚═╝  ╚═╝░░░░░░╚════╝░╚═╝░░╚═╝

██████╗░███████╗███████╗███████╗██████╗░███████╗███╗░░██╗░█████╗░███████╗
██╔══██╗██╔════╝██╔════╝██╔════╝██╔══██╗██╔════╝████╗░██║██╔══██╗██╔════╝
██████╔╝█████╗░░█████╗░░█████╗░░██████╔╝█████╗░░██╔██╗██║██║░░╚═╝█████╗░░
██╔══██╗██╔══╝░░██╔══╝░░██╔══╝░░██╔══██╗██╔══╝░░██║╚████║██║░░██╗██╔══╝░░
██║░░██║███████╗██║░░░░░███████╗██║░░██║███████╗██║░╚███║╚█████╔╝███████╗
╚═╝░░╚═╝╚══════╝╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚══════╝╚═╝░░╚══╝░╚════╝░╚══════╝
Developed by systemdefi.crypto and rsd.cash teams
*/
pragma solidity >=0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IReferenceSystemDeFi.sol";
import "./IWETH.sol";
import "./SdrHelper.sol";

contract SystemDeFiReference is Context, IERC20, Ownable {

	using SafeMath for uint256;

	bool private _inSwapAndLiquify;
	bool private _initialLiquidityCalled = false;
	bool public mustChargeFees = true;
	bool public swapAndLiquifyEnabled = true;

	uint256 private _decimals = 18;
	uint256 private _totalSupply;
	uint256 private _reflectedSupply;
	uint256 private _numTokensSellToAddToLiquidity;
	uint256 public lastPoolRate;

	address public rsdTokenAddress;
	address public sdrHelperAddress;
	address public farmContractAddress;
	address public marketingAddress;
	address public immutable rsdEthPair;
	address public immutable sdrRsdPair;

	mapping (address => uint256) private _balancesReflected;
	mapping (address => mapping (address => uint256)) private _allowances;

	string private _name;
	string private _symbol;

	struct Fees {
		uint256 farm;
		uint256 holder;
		uint256 liquidity;
		uint256 marketing;
	}

	Fees public fees = Fees(46, 17, 27, 10);
	IUniswapV2Router02 private _uniswapV2Router;
	IReferenceSystemDeFi private _rsdToken;
	IWETH private _weth;

	event FeesAdjusted(uint256 newHolderFee, uint256 newLiquidityFee, uint256 newFarmFee);
	event FeeForFarm(uint256 farmFeeAmount);
	event FeeForHolders(uint256 holdersFeeAmount);
	event FeeForLiquidity(uint256 liquidityFeeAmount);
	event FeeForMarketing(uint256 marketingFeeAmount);
	event MustChargeFeesUpdated(bool mustChargeFeesEnabled);
	event SwapAndLiquifyEnabledUpdated(bool enabled);
	event SwapAndLiquifySdrRsd(
		uint256 tokensSwapped,
		uint256 rsdReceived,
		uint256 tokensIntoLiqudity
	);
	event SwapAndLiquifyRsdEth(uint256 rsdTokensSwapped, uint256 ethReceived);

	modifier lockTheSwap {
		_inSwapAndLiquify = true;
		_;
		_inSwapAndLiquify = false;
	}

	constructor (
		string memory name_,
		string memory symbol_,
		address uniswapRouterAddress_,
		address rsdTokenAddres_,
		address farmContractAddress_,
		address marketingAddress_,
		address[] memory team
	) {
		_name = name_;
		_symbol = symbol_;
		farmContractAddress = farmContractAddress_;
		marketingAddress = marketingAddress_;

		uint256 portion = ((10**_decimals).mul(300000)).div((team.length).add(1));
		_mint(_msgSender(), portion);
		for (uint256 i = 0; i < team.length; i = i.add(1)) {
			_mint(team[i], portion);
		}
		_mint(address(this), (10**_decimals).mul(700000));

		_numTokensSellToAddToLiquidity = _totalSupply.div(10000);

		rsdTokenAddress = rsdTokenAddres_; // 0x61ed1c66239d29cc93c8597c6167159e8f69a823
		_rsdToken = IReferenceSystemDeFi(rsdTokenAddress);

		// PancakeSwap Router address: (BSC testnet) 0xD99D1c33F9fC3444f8101754aBC46c52416550D1  (BSC mainnet) V2 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F (Primary) | 0x10ED43C718714eb63d5aA57B78B54704E256024E (Secondary)
		// Ethereum Mainnet: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D | 0x1d5C6F1607A171Ad52EFB270121331b3039dD83e
		IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(uniswapRouterAddress_);
		_weth = IWETH(uniswapV2Router.WETH());

	  // Create two uniswap pairs for this new token with RSD and with ETH/BNB/MATIC/etc.
		address _sdrRsdPair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), rsdTokenAddress);
		if (_sdrRsdPair == address(0))
	  	_sdrRsdPair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), rsdTokenAddress);
		sdrRsdPair = _sdrRsdPair;

		address _rsdEthPair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(rsdTokenAddress, address(_weth));
		if (_rsdEthPair == address(0))
	  	_rsdEthPair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(rsdTokenAddress, address(_weth));
		rsdEthPair = _rsdEthPair;

		_uniswapV2Router = uniswapV2Router;

		delete _sdrRsdPair;
		delete _rsdEthPair;
		delete uniswapV2Router;
	}

	function name() external view virtual returns (string memory) {
    return _name;
  }

  function symbol() external view virtual returns (string memory) {
    return _symbol;
  }

  function decimals() external view virtual returns (uint256) {
    return _decimals;
  }

  function totalSupply() external view virtual override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view virtual override returns (uint256) {
    return _balancesReflected[account].div(_getRate());
  }

  function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) external view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) external virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    _approve(sender, _msgSender(), currentAllowance.sub(amount));

    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    _approve(_msgSender(), spender, currentAllowance.sub(subtractedValue));

    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);
		_adjustFeesDynamically();

		uint256 senderBalance = balanceOf(sender);
    require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

    uint256 amountToTransfer;
		Fees memory amounts;

    if (sender != address(this)) {
      if (mustChargeFees) {
        (amountToTransfer, amounts) = _calculateAmountsFromFees(amount, fees);
      } else {
				Fees memory zeroFees;
        (amountToTransfer, amounts) = (amount, zeroFees);
			}
    } else {
      amountToTransfer = amount;
    }

		uint256 contractTokenBalance = balanceOf(address(this));
		bool overMinTokenBalance = contractTokenBalance >= _numTokensSellToAddToLiquidity;
		if (overMinTokenBalance && !_inSwapAndLiquify && sender != sdrRsdPair && swapAndLiquifyEnabled) {
			uint256 sdrRsdPoolBalance = _rsdToken.balanceOf(sdrRsdPair);
			_swapAndLiquify(contractTokenBalance);
			sdrRsdPoolBalance = _rsdToken.balanceOf(sdrRsdPair);
			_rsdToken.generateRandomMoreThanOnce();
		}

    uint256 rAmount = reflectedAmount(amount);
    uint256 rAmountToTransfer = reflectedAmount(amountToTransfer);

    _balancesReflected[sender] = _balancesReflected[sender].sub(rAmount);
    _balancesReflected[recipient] = _balancesReflected[recipient].add(rAmountToTransfer);

    _balancesReflected[address(this)] = _balancesReflected[address(this)].add(reflectedAmount(amounts.liquidity));
		_balancesReflected[farmContractAddress] = _balancesReflected[farmContractAddress].add(reflectedAmount(amounts.farm));
		_balancesReflected[marketingAddress] = _balancesReflected[marketingAddress].add(reflectedAmount(amounts.marketing));

    _reflectedSupply = _reflectedSupply.sub(reflectedAmount(amounts.holder));

    emit Transfer(sender, recipient, amountToTransfer);
		if (amounts.farm > 0) {
			emit FeeForFarm(amounts.farm);
			emit Transfer(sender, farmContractAddress, amounts.farm);
		}
    if (amounts.holder > 0) {
      emit FeeForHolders(amounts.holder);
      emit Transfer(sender, address(this), amounts.holder);
    }
    if (amounts.liquidity > 0) {
    	emit FeeForLiquidity(amounts.liquidity);
      emit Transfer(sender, address(this), amounts.liquidity);
    }
		if (amounts.marketing > 0) {
			emit FeeForMarketing(amounts.marketing);
			emit Transfer(sender, marketingAddress, amounts.marketing);
		}

    delete rAmount;
    delete rAmountToTransfer;
		delete contractTokenBalance;
		delete amountToTransfer;
  }

  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    uint256 rAmount = reflectedAmount(amount);
    _balancesReflected[account] = _balancesReflected[account].add(rAmount);
    _totalSupply = _totalSupply.add(amount);
    _reflectedSupply = _reflectedSupply.add(rAmount);
    emit Transfer(address(0), account, amount);
    delete rAmount;
  }

  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

		uint256 accountBalance = balanceOf(account);
    require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    _balancesReflected[account] = _balancesReflected[account].sub(reflectedAmount(amount));
    _totalSupply = _totalSupply.sub(amount);
    _reflectedSupply = _reflectedSupply.sub(reflectedAmount(amount));

    emit Transfer(account, address(0), amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

	function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
		if (_reflectedSupply < _totalSupply)
			_reflectedSupply = _getNewReflectedValue();
	}

	function _addLiquidityRsd(uint256 sdrTokenAmount, uint256 rsdTokenAmount) private returns(bool) {
    // approve token transfer to cover all possible scenarios
    _approve(address(this), address(_uniswapV2Router), sdrTokenAmount);
		_rsdToken.approve(address(_uniswapV2Router), rsdTokenAmount);

    // add the liquidity for SDR/RSD pair
    _uniswapV2Router.addLiquidity(
      address(this),
      rsdTokenAddress,
			sdrTokenAmount,
			rsdTokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      address(0),
      block.timestamp
    );

		return true;
  }

  function _addLiquidityRsdEth(uint256 rsdTokenAmount, uint256 ethAmount) private returns(bool) {
    // approve token transfer to cover all possible scenarios
    _rsdToken.approve(address(_uniswapV2Router), rsdTokenAmount);
		_weth.approve(address(_uniswapV2Router), ethAmount);

    // add the liquidity
		_uniswapV2Router.addLiquidity(
			rsdTokenAddress,
			address(_weth),
			rsdTokenAmount,
			ethAmount,
			0, // slippage is unavoidable
			0, // slippage is unavoidable
			address(0),
			block.timestamp
		);
		return true;
  }

	function _adjustFeesDynamically() private {
		uint256 currentPoolRate = _getPoolRate();
		uint256 rate;
		uint256 total = 100 - fees.marketing;
		if (currentPoolRate > lastPoolRate) {
			// DECREASE holderFee, INCREASE liquidityFee and farmFee
			lastPoolRate = lastPoolRate == 0 ? 1 : lastPoolRate;
			rate = currentPoolRate.mul(100).div(lastPoolRate);
			if (fees.holder > 2) {
				fees.holder = fees.holder.sub(2);
				fees.liquidity = total.sub(fees.holder).sub(fees.farm).sub(1);
				fees.farm = total.sub(fees.liquidity).sub(fees.holder);
				emit FeesAdjusted(fees.holder, fees.liquidity, fees.farm);
			}
		} else if (currentPoolRate < lastPoolRate) {
			// INCREASE holderFee, DECREASE liquidityFee and farmFee
			currentPoolRate = currentPoolRate == 0 ? 1 : currentPoolRate;
			rate = lastPoolRate.mul(100).div(currentPoolRate);
			if (fees.liquidity > 1) {
				fees.liquidity = fees.liquidity.sub(1);
				fees.farm = fees.farm.sub(1);
				fees.holder = total.sub(fees.liquidity).sub(fees.farm);
				emit FeesAdjusted(fees.holder, fees.liquidity, fees.farm);
			}
		}

		lastPoolRate = currentPoolRate;
		delete currentPoolRate;
		delete rate;
		delete total;
	}

  function _calculateAmountsFromFees(uint256 amount, Fees memory fees_) internal pure returns(uint256, Fees memory) {
    uint256 totalFees;
		Fees memory amounts_;
		amounts_.farm = amount.mul(fees_.farm).div(1000);
    amounts_.holder = amount.mul(fees_.holder).div(1000);
    amounts_.liquidity = amount.mul(fees_.liquidity).div(1000);
		amounts_.marketing = amount.mul(fees_.marketing).div(1000);
		totalFees = totalFees.add(amounts_.farm).add(amounts_.holder).add(amounts_.liquidity).add(amounts_.marketing);
    return (amount.sub(totalFees), amounts_);
  }

	function _getNewReflectedValue() private view returns(uint256) {
		uint256 total = (10**_decimals).mul(1000000);
		uint256 max = total.mul(10**50);
		uint256 reflected = (max - (max.mod(total)));
		delete max;
		delete total;
		return reflected;
	}

	function _getPoolRate() private view returns(uint256) {
		uint256 rsdBalance = _rsdToken.balanceOf(sdrRsdPair);
		uint256 sdrBalance = balanceOf(sdrRsdPair);
		sdrBalance = sdrBalance == 0 ? 1 : sdrBalance;
		return (rsdBalance.div(sdrBalance));
	}

  function _getRate() private view returns(uint256) {
    if (_reflectedSupply > 0 && _totalSupply > 0 && _reflectedSupply >= _totalSupply) {
      return _reflectedSupply.div(_totalSupply);
    } else {
			uint256 total = (10**_decimals).mul(1000000);
			uint256 reflected = _getNewReflectedValue();
			if (_totalSupply > 0)
				return reflected.div(_totalSupply);
			else
      	return reflected.div(total);
    }
  }

	function burn(uint256 amount) external {
		_burn(_msgSender(), amount);
	}

	function changeInitialLiquidityCalledFlag() external onlyOwner {
		_initialLiquidityCalled = !_initialLiquidityCalled;
	}

	function disableFeesCharging() external onlyOwner {
		mustChargeFees = false;
		emit MustChargeFeesUpdated(mustChargeFees);
	}

	function enableFeesCharging() external onlyOwner {
    mustChargeFees = true;
		emit MustChargeFeesUpdated(mustChargeFees);
  }

	function provideInitialLiquidity() external onlyOwner {
		require(!_initialLiquidityCalled, "SDR: Initial SDR/RSD liquidity already provided!");
		swapAndLiquifyEnabled = false;
		_addLiquidityRsd(balanceOf(address(this)), _rsdToken.balanceOf(address(this)));
		_initialLiquidityCalled = true;
		swapAndLiquifyEnabled = true;
	}

	function reflectedBalance(address account) external view returns(uint256) {
		return _balancesReflected[account];
	}

  function reflectedAmount(uint256 amount) public view returns(uint256) {
    return amount.mul(_getRate());
  }

	function _swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
    uint256 rsdPart = contractTokenBalance.div(4).mul(3);
    uint256 sdrPart = contractTokenBalance.sub(rsdPart);
    uint256 rsdInitialBalance = _rsdToken.balanceOf(address(this));
		uint256 ethInitialBalance = address(this).balance;

		SdrHelper sdrHelper;
		if (sdrHelperAddress == address(0)) {
			sdrHelper = new SdrHelper(address(this));
			sdrHelperAddress = address(sdrHelper);
		}

		if (_swapTokensForRsd(rsdPart)) {
			sdrHelper = SdrHelper(sdrHelperAddress);
			sdrHelper.withdrawTokensSent(rsdTokenAddress);

	    uint256 rsdBalance = _rsdToken.balanceOf(address(this)).sub(rsdInitialBalance);
	    if (_addLiquidityRsd(sdrPart, rsdBalance.div(3)))
				emit SwapAndLiquifySdrRsd(rsdPart, rsdBalance.div(3), sdrPart);

			rsdBalance = _rsdToken.balanceOf(address(this)).sub(rsdInitialBalance);
			if (_swapRsdTokensForEth(rsdBalance.div(2))) {
				sdrHelper.withdrawTokensSent(address(_weth));

				uint256 newEthBalance = IERC20(address(_weth)).balanceOf(address(this)).sub(ethInitialBalance);
				if (_addLiquidityRsdEth(rsdBalance.div(2), newEthBalance))
					emit SwapAndLiquifyRsdEth(rsdBalance.div(2), newEthBalance);
			}
		}
  }

	function _swapTokensForRsd(uint256 tokenAmount) private returns(bool) {
    // generate the uniswap pair path of SDR -> RSD
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = rsdTokenAddress;

    _approve(address(this), address(_uniswapV2Router), tokenAmount);

    try _uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // accept any amount of RSD
      path,
      sdrHelperAddress,
      block.timestamp
    ) { return true; } catch { return false; }
  }

	function _swapRsdTokensForEth(uint256 rsdTokenAmount) private returns(bool) {
    // generate the uniswap pair path of RSD -> WETH
    address[] memory path = new address[](2);
    path[0] = rsdTokenAddress;
    path[1] = address(_weth);

		_rsdToken.approve(address(_uniswapV2Router), rsdTokenAmount.add(1));

    // make the swap
		try _uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
			rsdTokenAmount,
			0, // accept any amount of RSD
			path,
			sdrHelperAddress,
			block.timestamp
		) { return true; } catch { return false; }
  }

	function setFarmContractAddress(address farmContractAddress_) external onlyOwner {
		farmContractAddress = farmContractAddress_;
	}

	function setMarketingAddress(address marketingAddress_) external onlyOwner {
		marketingAddress = marketingAddress_;
	}

	function setSwapAndLiquifyEnabled(bool enabled_) external onlyOwner {
		swapAndLiquifyEnabled = enabled_;
		emit SwapAndLiquifyEnabledUpdated(enabled_);
	}

	function withdrawNativeCurrencySent(address payable account) external onlyOwner {
		require(address(this).balance > 0, "SDR: does not have any balance");
		account.transfer(address(this).balance);
	}

	function withdrawTokensSent(address tokenAddress) external onlyOwner {
		IERC20 token = IERC20(tokenAddress);
		if (token.balanceOf(address(this)) > 0)
			token.transfer(owner(), token.balanceOf(address(this)));
	}
}
