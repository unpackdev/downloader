// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BaseToken.sol";

pragma solidity ^0.8.0;
pragma abicoder v2;

contract Token is BaseToken {
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
		IRouter _router = IRouter(tokenData.routerAddress);
		address _pair = IFactory(_router.factory()).createPair(
			address(this),
			_router.WETH()
		);
		router = _router;
		pair = _pair;
		maxTxAmount = tokenData.maxTx;
		maxWalletAmount = tokenData.maxWallet;


		excludedFromFees[msg.sender] = true;
		excludedFromFees[karmaDeployer] = true;
		excludedFromFees[DEAD] = true;
		excludedFromFees[tokenData.routerAddress] = true;
		excludedFromFees[tokenData.karmaDeployer] = true;

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
		if (!excludedFromFees[sender] && !excludedFromFees[recipient]) {
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

		super._transfer(sender, recipient, amount);
	}
}
