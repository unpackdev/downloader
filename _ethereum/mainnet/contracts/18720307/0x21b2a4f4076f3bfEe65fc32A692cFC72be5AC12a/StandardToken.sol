//SPDX-License-Identifier: BUSL-1.1

import "./BaseToken.sol";

pragma solidity ^0.8.0;
pragma abicoder v2;

contract StandardToken is BaseToken {
	using SafeMathUpgradeable for uint256;
	using AddressUpgradeable for address payable;

	mapping(address => uint256) private _balances;

	bool private swapping;
	bool public swapEnabled;

	uint256 public swapThreshold;

	address public marketingWallet;

	uint256 public sellTax = 0;
	uint256 public buyTax = 0;

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
		excludedFromFees[DEAD] = true;
		excludedFromFees[tokenData.routerAddress] = true;
		excludedFromFees[tokenData.karmaDeployer] = true;

		router = IRouter(tokenData.routerAddress);
		pair = IFactory(router.factory()).createPair(
			address(this),
			router.WETH()
		);

		swapThreshold = tokenData.supply / 100; // 1% by default
		maxTxAmount = tokenData.maxTx;
		maxWalletAmount = tokenData.maxWallet;

		buyTax = tokenData.buyTax.marketing;
		sellTax = tokenData.sellTax.marketing;

		marketingWallet = tokenData.marketingWallet;

		excludedFromFees[address(this)] = true;
		excludedFromFees[marketingWallet] = true;

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
			require(amount <= maxTxAmount, "You are exceeding maxTxAmount");
			if (recipient != pair) {
				require(
					balanceOf(recipient) + amount <= maxWalletAmount,
					"You are exceeding maxWalletAmount"
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
				fee = (amount * sellTax) / 1000;
			} else {
				fee = (amount * buyTax) / 1000;
			}
		}

		//send fees if threshold has been reached
		//don't do this on buys, breaks swap
		if (swapEnabled && !swapping && sender != pair && fee > 0)
			swapForFees();

		super._transfer(sender, recipient, amount - fee);
		if (fee > 0) super._transfer(sender, address(this), fee);
	}

	function swapForFees() private inSwap {
		uint256 contractBalance = balanceOf(address(this));
		if (contractBalance >= swapThreshold) {
			swapTokensForETH(contractBalance);
			uint256 marketingAmt = address(this).balance;
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

	function setTaxes(uint256 _buy, uint256 _sell) external onlyLimitedOrOwner {
		require(_buy <= 150, "Buy > 15%");
		require(_sell <= 150, "Sell > 15%");
		require(
			(_buy < buyTax && msg.sender == limitedOwner()) ||
				(msg.sender == karmaDeployer && owner() == karmaDeployer),
			"Only Karma deployer can increase buy taxes"
		);
		require(
			(_sell < sellTax && msg.sender == limitedOwner()) ||
				(msg.sender == karmaDeployer && owner() == karmaDeployer),
			"Only Karma deployer can increase sell taxes"
		);
		buyTax = _buy;
		sellTax = _sell;
	}

	function updateMarketingWallet(address newWallet) external onlyOwner {
		marketingWallet = newWallet;
	}

	function manualSwap(uint256 amount) external onlyOwner {
		swapTokensForETH(amount);
		payable(marketingWallet).sendValue(address(this).balance);
	}
}
