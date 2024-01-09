pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./ExchangeWithOrionPool.sol";
import "./IOrionPoolV2Router02Ext.sol";
import "./IERC20.sol";
import "./ECDSA.sol";
import "./LibAtomic.sol";

contract ExchangeWithAtomic is ExchangeWithOrionPool {
    mapping(bytes32 => LibAtomic.LockOrder) public atomicSwaps;
    mapping(bytes32 => LibAtomic.RedeemInfo) public secrets;

    event AtomicLocked(
        address sender,
        address asset,
        bytes32 secretHash
    );

    event AtomicRedeemed(
        address sender,
        address receiver,
        address asset,
        bytes secret
    );

    event AtomicClaimed(
        address receiver,
        address asset,
        bytes secret
    );

    event AtomicRefunded(
        address receiver,
        address asset,
        bytes32 secretHash
    );

    function lockAtomic(LibAtomic.LockOrder memory swap) payable public nonReentrant {
        LibAtomic.doLockAtomic(swap, atomicSwaps, secrets, assetBalances, liabilities);

        require(checkPosition(swap.sender), "E1PA");

        emit AtomicLocked(swap.sender, swap.asset, swap.secretHash);
    }

    function redeemAtomic(LibAtomic.RedeemOrder calldata order, bytes calldata secret) public nonReentrant {
        LibAtomic.doRedeemAtomic(order, secret, secrets, assetBalances, liabilities);
        require(checkPosition(order.sender), "E1PA");

        emit AtomicRedeemed(order.sender, order.receiver, order.asset, secret);
    }

    function claimAtomic(address receiver, bytes calldata secret, bytes calldata matcherSignature) public nonReentrant {
        LibAtomic.LockOrder storage swap = LibAtomic.doClaimAtomic(
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

    function refundAtomic(bytes32 secretHash) public nonReentrant {
        LibAtomic.LockOrder storage swap = LibAtomic.doRefundAtomic(secretHash, atomicSwaps, assetBalances, liabilities);

        emit AtomicRefunded(swap.sender, swap.asset, swap.secretHash);
    }

    /* Error Codes
        E1: Insufficient Balance, flavor A - Atomic, PA - Position Atomic
        E17: Incorrect atomic secret, flavor: U - used, NF - not found, R - redeemed, E/NE - expired/not expired, ETH
   */
}

