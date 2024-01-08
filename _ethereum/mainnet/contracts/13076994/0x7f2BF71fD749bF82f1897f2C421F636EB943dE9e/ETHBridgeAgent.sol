// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./AbstractBridgeAgent.sol";
import "./SafeERC20.sol";
import "./ECDSA.sol";

/**
 * @title ETH implementation of the bridge agent
 *
 * The implementation of this agent is as follows:
 * 1. Token Owner registers a token with this agent (register())
 * 2. Token User deposits a token amount X to the agent contract (deposit())
 * 3. [off chain] Token User claims a token amount X in another chain
 * 4. [off chain] Token User deposits a token amount Y in another chain
 * 5. Token User claims a token amount Y and the balance is being transferred
 *    from the agent back to user (claim())
 *
 * See {AbstractBridgeAgent} documentation for some core concepts description.
 */
contract ETHBridgeAgent is AbstractBridgeAgent {
	using SafeERC20 for IERC20;
	using ECDSA for bytes32;

	/**
	 * @dev Initializes the agent
	 */
	constructor(address _bridgeSigner, address payable _treasurer)
		AbstractBridgeAgent(_bridgeSigner, _treasurer)
	// solhint-disable-next-line no-empty-blocks
	{

	}

	/**
	 * @dev Deposits a given amount of token that can be claimed in another chain.
	 *
	 * @param toChain target chain ID where the token amount will be claimed
	 * @param token address of a registered token to be deposited
	 * @param toWallet caller address that will claim the token from the {toChain}
	 * @param amount wei amount of token to be deposited/claimed
	 * @param bridgeSig signature issued by the Bridge Service
	 * @param sigExpire nonce/expiration issued by the Bridge Service
	 *
	 * This function is payable(), receiving service fee in the form of ether.
	 * The actual fee value is obtained from the Bridge Service along with {bridgeSig}
	 * and {sigExpire}.
	 *
	 * In this ETH-specific implementation, the agent transfers a given amount of
	 * token from a user to itself (agent). The amount is withhold until the user
	 * comes back from the subchain to claim it back.
	 *
	 * The Bridge Service monitors the chain and issue bridge/token signatures
	 * once the deposit transaction gets enough confirmations. The two signatures
	 * can later be obtained from the Bridge Service and used to claim the
	 * token amount in another chain.
	 *
	 * Requirements:
	 * - Agent must not be paused.
	 * - {token} must be registered in this agent.
	 * - {token} must not be paused.
	 * - {bridgeSig} cannot be reused and {sigExpire} must be after the current block time.
	 * - Caller should have enough {token} balance to afford the deposited {amount}.
	 */
	function deposit(
		uint256 toChain,
		address token,
		address toWallet,
		uint256 amount,
		bytes memory bridgeSig,
		uint256 sigExpire
	)
		external
		payable
		override
		useSignature(bridgeSig, sigExpire)
		whenNotPaused
	{
		require(!tokenPaused[token], "token is paused");
		require(tokenSigners[token] != address(0), "token not registered");

		// check signature
		bytes32 messageHash =
			keccak256(
				abi.encode(
					address(this),
					toChain,
					token,
					toWallet,
					amount,
					msg.value,
					sigExpire
				)
			);
		bytes32 ethHash = messageHash.toEthSignedMessageHash();
		require(
			ethHash.recover(bridgeSig) == bridgeSigner,
			"invalid bridge signature"
		);

		// Deposit the amount of token frmo user to the agent contract
		IERC20(token).safeTransferFrom(_msgSender(), address(this), amount);

		// User pays fee to the bridge
		if (msg.value > 0) {
			treasurer.transfer(msg.value);
		}

		emit Deposit(toChain, token, _msgSender(), toWallet, amount, msg.value);
	}

	/**
	 * @dev Transfers a given amount of token from agent to a user
	 *
	 * @param depositTx deposit transaction hash from another chain
	 * @param token address of the local token to be claimed
	 * @param amount wei amount of token to be claimed
	 * @param tokenSig signature of the Token Owner (obtained via Bridge Service)
	 * @param bridgeSig signature of the Bridge Service
	 *
	 * Once the deposit is done in another chain and the Bridge Service has
	 * issued token/bridge signature pair, the user can claim their token
	 * in this chain, by calling this function.
	 *
	 * This ETH-specific implementation transfers the withhold amount from the
	 * agent contract back to a user.
	 *
	 * Requirements:
	 * - Agent must not be paused.
	 * - {token} must be registered in this agent.
	 * - {token} must not be paused.
	 * - Caller should be the wallet that was specified in {toWallet} during {deposit()}
	 * - Valid {tokenSig} and {bridgeSig} obtained from the Bridge Service
	 */
	function claim(
		bytes32 depositTx,
		address token,
		uint256 amount,
		bytes memory tokenSig,
		bytes memory bridgeSig
	)
		external
		override
		useSignature(tokenSig, 0)
		useSignature(bridgeSig, 0)
		whenNotPaused
	{
		require(!tokenPaused[token], "token is paused");
		require(tokenSigners[token] != address(0), "token not registered");

		// check signature
		{
			bytes32 messageHash =
				keccak256(
					abi.encode(
						address(this),
						depositTx,
						token,
						block.chainid,
						_msgSender(),
						amount
					)
				);
			bytes32 ethHash = messageHash.toEthSignedMessageHash();
			require(
				ethHash.recover(tokenSig) == tokenSigners[token],
				"invalid token signature"
			);
			require(
				ethHash.recover(bridgeSig) == bridgeSigner,
				"invalid bridge signature"
			);
		}

		// Transfer the withhold amount of token back to a user
		IERC20(token).safeTransfer(_msgSender(), amount);

		emit Claim(depositTx, token, _msgSender(), amount);
	}
}
