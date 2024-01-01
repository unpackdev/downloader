// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "./Exchange.sol";
import "./LibAtomic.sol";

contract ExchangeWithAtomic is Exchange {
	uint256[2] private gap;
	address public WETH;
	mapping(bytes32 => LibAtomic.LockInfo) public atomicSwaps;
	mapping(bytes32 => bool) public secrets;

	event AtomicLocked(address sender, address asset, bytes32 secretHash);
	event AtomicRedeemed(address sender, address receiver, address asset, bytes secret);
	event AtomicClaimed(address receiver, address asset, bytes secret);
	event AtomicRefunded(address receiver, address asset, bytes32 secretHash);

	function setBasicParams(
		address orionToken,
		address priceOracleAddress,
		address allowedMatcher,
		address WETH_
	) public onlyOwner {
		_orionToken = IERC20(orionToken);
		_oracleAddress = priceOracleAddress;
		_allowedMatcher = allowedMatcher;
		WETH = WETH_;
	}

	function fillAndLockAtomic(
		LibAtomic.CrossChainOrder memory userOrder,
		LibValidator.Order memory brokerOrder,
		uint64 filledPrice,
		uint64 filledAmount,
		uint64 lockOrderExpiration
	) public onlyMatcher {
		address lockAsset;
		uint64 lockAmount;
		if (userOrder.limitOrder.buySide == 1) {
			fillOrders(userOrder.limitOrder, brokerOrder, filledPrice, filledAmount);
			lockAsset = userOrder.limitOrder.baseAsset;
			lockAmount = filledAmount;
		} else {
			fillOrders(brokerOrder, userOrder.limitOrder, filledPrice, filledAmount);
			lockAsset = userOrder.limitOrder.quoteAsset;
			lockAmount = (filledAmount * filledPrice) / 10 ** 8;
		}

		LibAtomic.LockOrder memory lockOrder = LibAtomic.LockOrder({
			sender: userOrder.limitOrder.matcherAddress,
			asset: lockAsset,
			amount: lockAmount,
			expiration: lockOrderExpiration,
			targetChainId: userOrder.chainId,
			secretHash: userOrder.secretHash
		});

		_lockAtomic(userOrder.limitOrder.senderAddress, lockOrder);
	}

	function lockAtomicByMatcher(address account, LibAtomic.LockOrder memory lockOrder) external onlyMatcher {
		_lockAtomic(account, lockOrder);
	}

	function _lockAtomic(address account, LibAtomic.LockOrder memory lockOrder) internal nonReentrant {
		LibAtomic.doLockAtomic(account, lockOrder, atomicSwaps, assetBalances, liabilities);

		if (!checkPosition(account)) revert IncorrectPosition();

		emit AtomicLocked(lockOrder.sender, lockOrder.asset, lockOrder.secretHash);
	}

	function lockAtomic(LibAtomic.LockOrder memory swap) public payable {
		_lockAtomic(msg.sender, swap);
	}

	function redeemAtomic(LibAtomic.RedeemOrder calldata order, bytes calldata secret) public {
		LibAtomic.doRedeemAtomic(order, secret, secrets, assetBalances, liabilities);
		if (!checkPosition(order.sender)) revert IncorrectPosition();

		emit AtomicRedeemed(order.sender, order.receiver, order.asset, secret);
	}

	function redeem2Atomics(
		LibAtomic.RedeemOrder calldata order1,
		bytes calldata secret1,
		LibAtomic.RedeemOrder calldata order2,
		bytes calldata secret2
	) public {
		redeemAtomic(order1, secret1);
		redeemAtomic(order2, secret2);
	}

	function claimAtomic(address receiver, bytes calldata secret, bytes calldata matcherSignature) public {
		LibAtomic.LockInfo storage swap = LibAtomic.doClaimAtomic(
			receiver,
			secret,
			matcherSignature,
			_allowedMatcher,
			atomicSwaps,
			assetBalances,
			liabilities
		);

		emit AtomicClaimed(receiver, swap.asset, secret);
	}

	function refundAtomic(bytes32 secretHash) public {
		LibAtomic.LockInfo storage swap = LibAtomic.doRefundAtomic(secretHash, atomicSwaps, assetBalances, liabilities);

		emit AtomicRefunded(swap.sender, swap.asset, secretHash);
	}

	/* Error Codes
        E1: Insufficient Balance, flavor A - Atomic, PA - Position Atomic
        E17: Incorrect atomic secret, flavor: U - used, NF - not found, R - redeemed, E/NE - expired/not expired, ETH
   */
}
