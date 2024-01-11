//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @title InstaLite Connector
 * @dev Supply, Withdraw & Deleverage
 */

import "./interfaces.sol";
import "./basic.sol";
import "./events.sol";
import "./interface.sol";

abstract contract InstaLiteConnector is Events, Basic {
	TokenInterface internal constant astethToken =
		TokenInterface(0x1982b2F5814301d4e9a8b0201555376e62F82428);

	/**
	 * @dev Supply ETH/ERC20
	 * @notice Supply a token into Instalite.
	 * @param vaultAddr Address of instaLite Contract.
	 * @param token The address of the token to be supplied. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of token to be supplied. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setIds array of IDs to store the amount of tokens deposited.
	 */
	function supply(
		address vaultAddr,
		address token,
		uint256 amt,
		uint256 getId,
		uint256[] memory setIds
	)
		public
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);
		bool isEth = token == ethAddr;
		uint256 vTokenAmt;

		if (isEth) {
			_amt = _amt == uint256(-1) ? address(this).balance : _amt;
			vTokenAmt = IInstaLite(vaultAddr).supplyEth{ value: amt }(
				address(this)
			);
		} else {
			TokenInterface tokenContract = TokenInterface(token);

			_amt = _amt == uint256(-1)
				? tokenContract.balanceOf(address(this))
				: _amt;

			approve(tokenContract, vaultAddr, _amt);
			vTokenAmt = IInstaLite(vaultAddr).supply(
				token,
				_amt,
				address(this)
			);
		}

		setUint(setIds[0], _amt);
		setUint(setIds[1], vTokenAmt);

		_eventName = "LogSupply(address,address,uint256,uint256,uint256,uint256[])";
		_eventParam = abi.encode(
			vaultAddr,
			token,
			vTokenAmt,
			_amt,
			getId,
			setIds
		);
	}

	/**
	 * @dev Withdraw ETH/ERC20
	 * @notice Withdraw deposited tokens from Instalite.
	 * @param vaultAddr Address of vaultAddress Contract.
	 * @param amt The amount of the token to withdraw.
	 * @param getId ID to retrieve amt.
	 * @param setIds array of IDs to stores the amount of tokens withdrawn.
	 */
	function withdraw(
		address vaultAddr,
		uint256 amt,
		uint256 getId,
		uint256[] memory setIds
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);

		uint256 vTokenAmt = IInstaLite(vaultAddr).withdraw(_amt, address(this));

		setUint(setIds[0], _amt);
		setUint(setIds[1], vTokenAmt);

		_eventName = "LogWithdraw(address,uint256,uint256,uint256,uint256[])";
		_eventParam = abi.encode(vaultAddr, _amt, vTokenAmt, getId, setIds);
	}

	/**
	 * @dev Deleverage vault. Pays back ETH debt and get stETH collateral. 1:1 swap of ETH to stETH
	 * @notice Deleverage Instalite vault.
	 * @param vaultAddr Address of vaultAddress Contract.
	 * @param amt The amount of the token to deleverage.
	 * @param getId ID to retrieve amt.
	 * @param setId ID to set amt.
	 */
	function deleverage(
		address vaultAddr,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);

		uint256 initialBal = astethToken.balanceOf(address(this));

		approve(TokenInterface(wethAddr), vaultAddr, _amt);

		IInstaLite(vaultAddr).deleverage(_amt);

		uint256 finalBal = astethToken.balanceOf(address(this));

		require(amt <= (1e9 + finalBal - initialBal), "lack-of-steth");

		setUint(setId, _amt);

		_eventName = "LogDeleverage(address,uint256,uint256,uint256)";
		_eventParam = abi.encode(vaultAddr, _amt, getId, setId);
	}

	/**
	 * @dev Deleverage and Withdraw vault. Pays back weth debt and get stETH/WETH collateral.
	 * @notice Deleverage Instalite vault.
	 * @param vaultAddr Address of vaultAddress Contract.
	 * @param deleverageAmount The amount of the token to deleverage.
	 * @param withdrawAmount The amount of the token to withdraw.
	 * @param getIds ID to retrieve amt.
	 * @param setIds ID to set amt.
	 */
	function deleverageAndWithdraw(
		address vaultAddr,
		uint256 deleverageAmount,
		uint256 withdrawAmount,
		uint256[] memory getIds,
		uint256[] memory setIds
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		require(getIds.length > 2, "invalid get-ids length");
		uint256 _deleverageAmt = getUint(getIds[0], deleverageAmount);
		uint256 _withdrawAmount = getUint(getIds[1], withdrawAmount);

		TokenInterface tokenContract = 0xc383a3833A87009fD9597F8184979AF5eDFad019 ==
				vaultAddr
				? TokenInterface(wethAddr)
				: TokenInterface(IInstaLite(vaultAddr).token());

		uint256 initialBalStETH = astethToken.balanceOf(address(this));
		uint256 initialBalToken = tokenContract.balanceOf(address(this));

		approve(TokenInterface(wethAddr), vaultAddr, _deleverageAmt);

		IInstaLite(vaultAddr).deleverageAndWithdraw(
			_deleverageAmt,
			_withdrawAmount,
			address(this)
		);

		uint256 _stETHAmt = astethToken.balanceOf(address(this)) -
			initialBalStETH;
		uint256 _tokenAmt = tokenContract.balanceOf(address(this)) -
			initialBalToken;

		// TODO: add require conditions
		if (setIds.length > 2) {
			setUint(setIds[0], _stETHAmt);
			setUint(setIds[1], _tokenAmt);
		}

		_eventName = "LogDeleverageAndWithdraw(address,uint256,uint256,uint256,uint256,uint256[],uint256[])";
		_eventParam = abi.encode(
			vaultAddr,
			_deleverageAmt,
			_withdrawAmount,
			_stETHAmt,
			_tokenAmt,
			getIds,
			setIds
		);
	}
}

contract ConnectV2InstaLite is InstaLiteConnector {
	string public constant name = "InstaLite-v1.1";
}
