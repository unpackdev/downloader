// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

interface IUniswapV2Factory {
	function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router01 {
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

interface IUniswapV2Router02 is IUniswapV2Router01 {
	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external;
}

contract Santa is ERC20, Ownable {
	IUniswapV2Router02 public immutable router;
	address public immutable uniswapV2Pair;

	// addresses
	address public hospitalWallet;

	// limits
	uint256 private maxBuyAmount;
	uint256 private maxSellAmount;
	uint256 private maxWalletAmount;

	uint256 private thresholdSwapAmount;

	// status flags
	bool private isTrading = false;
	bool public swapEnabled = false;
	bool public isSwapping;

	struct Fees {
		uint8 buyTotalFees;
		uint8 buySantaFee;
		uint8 buyLiquidityFee;
		uint8 sellTotalFees;
		uint8 sellSantaFee;
		uint8 sellLiquidityFee;
	}

	Fees public _fees =
		Fees({
			buyTotalFees: 0,
			buySantaFee: 0,
			buyLiquidityFee: 0,
			sellTotalFees: 0,
			sellSantaFee: 0,
			sellLiquidityFee: 0
		});

	uint256 public tokensForLiquidity;
	uint256 public tokensForSanta;
	uint256 private taxTill;
	// exclude from fees and max transaction amount
	mapping(address => bool) private _isExcludedFromFees;
	mapping(address => bool) public _isExcludedMaxTransactionAmount;
	mapping(address => bool) public _isExcludedMaxWalletAmount;

	// store addresses that a automatic market maker pairs. Any transfer *to* these addresses
	// could be subject to a maximum transfer amount
	mapping(address => bool) public marketPair;

	event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived);

	modifier lockTheSwap() {
		isSwapping = true;
		_;
		isSwapping = false;
	}

	constructor(
		address _hospitalWallet,
		string memory _name,
		string memory _symbol,
		uint256 _totalSupply
	) ERC20(_name, _symbol) {
		router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

		uniswapV2Pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());

		_isExcludedMaxTransactionAmount[address(router)] = true;
		_isExcludedMaxTransactionAmount[address(uniswapV2Pair)] = true;
		_isExcludedMaxTransactionAmount[owner()] = true;
		_isExcludedMaxTransactionAmount[address(this)] = true;

		_isExcludedFromFees[owner()] = true;
		_isExcludedFromFees[address(this)] = true;

		_isExcludedMaxWalletAmount[owner()] = true;
		_isExcludedMaxWalletAmount[address(this)] = true;
		_isExcludedMaxWalletAmount[address(uniswapV2Pair)] = true;

		marketPair[address(uniswapV2Pair)] = true;

		approve(address(router), type(uint256).max);

		maxBuyAmount = (_totalSupply * 2) / 100; // 2% maxTransactionAmountTxn
		maxSellAmount = (_totalSupply * 2) / 100; // 2% maxTransactionAmountTxn
		maxWalletAmount = (_totalSupply * 2) / 100; // 2% maxWallet
		thresholdSwapAmount = (_totalSupply * 1) / 10000; // 0.01% swap wallet

		_fees.buyLiquidityFee = 1;
		_fees.buySantaFee = 1;
		_fees.buyTotalFees = _fees.buyLiquidityFee + _fees.buySantaFee;

		_fees.sellLiquidityFee = 1;
		_fees.sellSantaFee = 1;
		_fees.sellTotalFees = _fees.sellLiquidityFee + _fees.sellSantaFee;

		hospitalWallet = _hospitalWallet;

		_mint(msg.sender, _totalSupply);
	}

	receive() external payable {}

	// once enabled, can never be turned off
	function swapTrading() external onlyOwner {
		isTrading = true;
		swapEnabled = true;
		taxTill = block.number + 2;
	}

	function isExcludedFromFees(address account) public view returns (bool) {
		return _isExcludedFromFees[account];
	}

	function _transfer(address sender, address recipient, uint256 amount) internal override {
		if (amount == 0) {
			super._transfer(sender, recipient, 0);
			return;
		}

		if (sender != owner() && recipient != owner() && !isSwapping) {
			if (!isTrading) {
				require(_isExcludedFromFees[sender] || _isExcludedFromFees[recipient], "Trading is not active.");
			}
			if (marketPair[sender] && !_isExcludedMaxTransactionAmount[recipient]) {
				require(amount <= maxBuyAmount, "buy transfer over max amount");
			} else if (marketPair[recipient] && !_isExcludedMaxTransactionAmount[sender]) {
				require(amount <= maxSellAmount, "Sell transfer over max amount");
			}

			if (!_isExcludedMaxWalletAmount[recipient]) {
				require(amount + balanceOf(recipient) <= maxWalletAmount, "Max wallet exceeded");
			}
		}

		uint256 contractTokenBalance = balanceOf(address(this));

		bool canSwap = contractTokenBalance >= thresholdSwapAmount;

		if (
			canSwap &&
			swapEnabled &&
			!isSwapping &&
			marketPair[recipient] &&
			!_isExcludedFromFees[sender] &&
			!_isExcludedFromFees[recipient]
		) {
			swapBack();
		}

		bool takeFee = !isSwapping;

		// if any account belongs to _isExcludedFromFee account then remove the fee
		if (_isExcludedFromFees[sender] || _isExcludedFromFees[recipient]) {
			takeFee = false;
		}

		// only take fees on buys/sells, do not take on wallet transfers
		if (takeFee) {
			uint256 fees = 0;
			if (block.number < taxTill) {
				fees = (amount * 99) / 100;
				tokensForSanta += (fees * 5) / 99;
			} else if (marketPair[recipient] && _fees.sellTotalFees > 0) {
				fees = (amount * _fees.sellTotalFees) / 100;
				tokensForLiquidity += (fees * _fees.sellLiquidityFee) / _fees.sellTotalFees;
				tokensForSanta += (fees * _fees.sellSantaFee) / _fees.sellTotalFees;
			}
			// on buy
			else if (marketPair[sender] && _fees.buyTotalFees > 0) {
				fees = (amount * _fees.buyTotalFees) / 100;
				tokensForLiquidity += (fees * _fees.buyLiquidityFee) / _fees.buyTotalFees;
				tokensForSanta += (fees * _fees.buySantaFee) / _fees.buyTotalFees;
			}

			if (fees > 0) {
				super._transfer(sender, address(this), fees);
			}

			amount -= fees;
		}

		super._transfer(sender, recipient, amount);
	}

	function swapTokensForEth(uint256 tAmount) private {
		// generate the uniswap pair path of token -> weth
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = router.WETH();

		_approve(address(this), address(router), tAmount);

		// make the swap
		router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tAmount,
			0, // accept any amount of ETH
			path,
			address(this),
			block.timestamp
		);
	}

	function addLiquidity(uint256 tAmount, uint256 ethAmount) private {
		// approve token transfer to cover all possible scenarios
		_approve(address(this), address(router), tAmount);

		// add the liquidity
		router.addLiquidityETH{ value: ethAmount }(address(this), tAmount, 0, 0, address(this), block.timestamp);
	}

	function swapBack() private lockTheSwap {
		uint256 contractTokenBalance = balanceOf(address(this));
		uint256 toSwap = tokensForLiquidity + tokensForSanta;
		bool success;

		if (contractTokenBalance == 0 || toSwap == 0) {
			return;
		}

		if (contractTokenBalance > thresholdSwapAmount * 20) {
			contractTokenBalance = thresholdSwapAmount * 20;
		}

		// Halve the amount of liquidity tokens
		uint256 liquidityTokens = (contractTokenBalance * tokensForLiquidity) / toSwap / 2;
		uint256 amountToSwapForETH = contractTokenBalance - liquidityTokens;

		uint256 initialETHBalance = address(this).balance;

		swapTokensForEth(amountToSwapForETH);

		uint256 newBalance = address(this).balance - initialETHBalance;

		uint256 ethForSanta = (newBalance * tokensForSanta) / toSwap;
		uint256 ethForLiquidity = newBalance - ethForSanta;

		tokensForLiquidity = 0;
		tokensForSanta = 0;

		if (liquidityTokens > 0 && ethForLiquidity > 0) {
			addLiquidity(liquidityTokens, ethForLiquidity);
			emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity);
		}

		(success, ) = address(hospitalWallet).call{ value: address(this).balance }("");
	}
}
