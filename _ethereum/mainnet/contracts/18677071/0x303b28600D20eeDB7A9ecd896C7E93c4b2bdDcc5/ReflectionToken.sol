//SPDX-License-Identifier: BUSL-1.1

import "./BaseToken.sol";
import "./SafeMathUpgradeable.sol";
import "./DividendDistributor.sol";

pragma solidity ^0.8.0;
pragma abicoder v2;

contract ReflectionToken is BaseToken {
	using AddressUpgradeable for address payable;
	using SafeMathUpgradeable for uint256;
	using SafeERC20Upgradeable for IERC20Upgradeable;

	mapping(address => uint256) private _balances;

	bool private swapping;
	bool public swapEnabled;

	uint256 public swapThreshold;

	address public marketingWallet;

	address public rewardToken;
	DividendDistributor public distributor;
	uint256 distributorGas = 500000;

	// M,R
	Taxes public taxes = Taxes(0, 0);
	Taxes public sellTaxes = Taxes(0, 0);
	uint256 public totTax = 0;
	uint256 public totSellTax = 0;

	uint256 public buyTaxReflection = 0;
	uint256 public sellTaxReflection = 0;

	mapping(address => bool) public isDividendExempt;

	modifier inSwap() {
		if (!swapping) {
			swapping = true;
			_;
			swapping = false;
		}
	}

	function initialize(
		TokenData calldata tokenData
	) public virtual override initializer {
		__BaseToken_init(
			tokenData.name,
			tokenData.symbol,
			tokenData.decimals,
			tokenData.supply,
			tokenData.limitedOwner
		);
		require(tokenData.maxTx > totalSupply() / 10000, "maxTxAmount < 0.01%");
		require(
			tokenData.maxWallet > totalSupply() / 10000,
			"maxWalletAmount < 0.01%"
		);

		karmaDeployer = tokenData.karmaDeployer;
		karmaCampaignFactory = tokenData.karmaCampaignFactory;
		excludedFromFees[msg.sender] = true;
		excludedFromFees[karmaDeployer] = true;

		router = IRouter(tokenData.routerAddress);
		pair = IFactory(router.factory()).createPair(
			address(this),
			router.WETH()
		);

		swapThreshold = tokenData.supply / 100; // 1% by default
		maxTxAmount = tokenData.maxTx;
		maxWalletAmount = tokenData.maxWallet;

		taxes = tokenData.buyTax;
		totTax = taxes.marketing + taxes.reflection;
		sellTaxes = tokenData.sellTax;
		totSellTax = sellTaxes.marketing + sellTaxes.reflection;

		marketingWallet = tokenData.marketingWallet;
		excludedFromFees[address(this)] = true;
		excludedFromFees[marketingWallet] = true;
		excludedFromFees[DEAD] = true;
		excludedFromFees[tokenData.routerAddress] = true;
		excludedFromFees[karmaDeployer] = true;

		rewardToken = tokenData.rewardToken;
		distributor = new DividendDistributor(
			tokenData.rewardToken,
			tokenData.routerAddress
		);

		isDividendExempt[pair] = true;
		isDividendExempt[address(this)] = true;
		isDividendExempt[marketingWallet] = true;
		isDividendExempt[DEAD] = true;

		if (tokenData.antiBot != address(0x0) && tokenData.antiBot != DEAD) {
			antibot = IKARMAAntiBot(tokenData.antiBot);
			antibot.setTokenOwner(msg.sender);
			enableAntiBot = true;
		}
	}

	function _transfer(
		address sender,
		address recipient,
		uint256 amount
	) internal override {
		require(amount > 0, "Transfer amount must be greater than zero");

		if (
			!excludedFromFees[sender] &&
			!excludedFromFees[recipient] &&
			!swapping
		) {
			require(tradingEnabled, "Trading not active yet");
			require(amount <= maxTxAmount, "over maxTxAmount");
			if (recipient != pair) {
				require(
					balanceOf(recipient) + amount <= maxWalletAmount,
					"over maxWalletAmount"
				);
			}
		}

		if (enableAntiBot) {
			antibot.onPreTransferCheck(sender, recipient, amount);
		}

		uint256 fee;

		//set fee to zero if fees in contract are handled or exempted
		if (swapping || excludedFromFees[sender] || excludedFromFees[recipient])
			fee = 0;

			//calculate fee
		else {
			if (recipient == pair) {
				fee = (amount * totSellTax) / 1000;
				sellTaxReflection = (amount * sellTaxes.reflection) / 1000;
			} else {
				fee = (amount * totTax) / 1000;
				buyTaxReflection = (amount * taxes.reflection) / 1000;
			}
		}

		//send fees if threshold has been reached
		//don't do this on buys, breaks swap
		if (swapEnabled && !swapping && sender != pair && fee > 0)
			swapForFees();

		super._transfer(sender, recipient, amount - fee);
		if (fee > 0) super._transfer(sender, address(this), fee);

		if (!isDividendExempt[sender]) {
			try distributor.setShare(sender, _balances[sender]) {} catch {}
		}
		if (!isDividendExempt[recipient]) {
			try
				distributor.setShare(recipient, _balances[recipient])
			{} catch {}
		}

		try distributor.process(distributorGas) {} catch {}
	}

	function setIsDividendExempt(
		address holder,
		bool exempt
	) external onlyOwner {
		require(holder != address(this) && holder != pair);
		isDividendExempt[holder] = exempt;
		if (exempt) {
			distributor.setShare(holder, 0);
		} else {
			distributor.setShare(holder, _balances[holder]);
		}
	}

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external onlyOwner {
		distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

	function setDistributorSettings(uint256 gas) external onlyLimitedOrOwner {
        require(gas < 750000);
        distributorGas = gas;
    }

	function claimDividend() external {
       distributor.claimDividend();
    }

	function swapForFees() private inSwap {
		uint256 contractBalance = balanceOf(address(this));
		if (contractBalance >= swapThreshold && contractBalance > 0) {
			uint256 initialETH = address(this).balance;
			swapTokensForETH(contractBalance);
			uint256 amountETH = address(this).balance.sub(initialETH);
			uint256 reflectionAmountETH = ((sellTaxReflection +
				buyTaxReflection) * amountETH) / contractBalance;

			bool success = false;
			try distributor.deposit{ value: reflectionAmountETH }() {
				success = true;
			} catch {}

			if (success) {
				sellTaxReflection = 0;
				buyTaxReflection = 0;
			}
			uint256 marketingAmt = amountETH - reflectionAmountETH;
			if (marketingAmt > 0) {
				payable(marketingWallet).sendValue(marketingAmt);
			}
		}
	}

	function swapTokensForETH(uint256 tokenAmount) private {
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = router.WETH();

		_approve(address(this), address(router), tokenAmount);

		// make the swap
		router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			0,
			path,
			address(this),
			block.timestamp
		);
	}

	function setSwapEnabled(bool state) external onlyOwner {
		swapEnabled = state;
	}

	function setSwapThreshold(uint256 new_amount) external onlyOwner {
		swapThreshold = new_amount;
	}

	function setTaxes(
		uint256 _marketing,
		uint256 _reflection
	) external onlyOwner {
		require(_marketing + _reflection <= 150, "Fee > 15%");
		require(
			(_marketing + _reflection < totTax &&
				msg.sender == limitedOwner()) ||
				(msg.sender == karmaDeployer && owner() == karmaDeployer),
			"Only Karma deployer can increase buy taxes"
		);
		taxes = Taxes(_marketing, _reflection);
		totTax = _marketing + _reflection;
	}

	function setSellTaxes(
		uint256 _marketing,
		uint256 _reflection
	) external onlyOwner {
		require(_marketing + _reflection <= 150, "Fee > 15%");
		require(
			(_marketing + _reflection < totSellTax &&
				msg.sender == limitedOwner()) ||
				(msg.sender == karmaDeployer && owner() == karmaDeployer),
			"Only Karma deployer can increase sell taxes"
		);
		sellTaxes = Taxes(_marketing, _reflection);
		totSellTax = _marketing + _reflection;
	}

	function updateMarketingWallet(address newWallet) external onlyOwner {
		marketingWallet = newWallet;
	}

	function manualSwap(
		uint256 amount,
		uint256 reflectionPercentage,
		uint256 marketingPercentage
	) external onlyOwner {
		uint256 initBalance = address(this).balance;
		swapTokensForETH(amount);
		uint256 newBalance = address(this).balance - initBalance;
		if (marketingPercentage > 0 && marketingWallet != address(0x0))
			payable(marketingWallet).sendValue(
				(newBalance * marketingPercentage) /
					(reflectionPercentage + marketingPercentage)
			);
	}
}
