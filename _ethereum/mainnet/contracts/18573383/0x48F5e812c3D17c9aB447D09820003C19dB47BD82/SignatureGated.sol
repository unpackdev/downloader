// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.16;

import "./ECDSA.sol";
import "./EnumerableSet.sol";

import "./Seller.sol";

library SignatureGatedLib {
    /**
     * @notice Message struct to encode allowances.
     * @param receiver The address to which the allowance is granted.
     * @param numMax The maximum number of purchases that can be made.
     * @param price The price per purchase.
     * @param activeAfterTimestamp The timestamp after which the allowance is active.
     * @param activeUntilTimestamp The timestamp after which the allowance is no longer active.
     * @dev The allowance is active in the timestamp interval [activeAfterTimestamp, activeUntilTimestamp).
     */
    struct Allowance {
        address receiver;
        uint64 numMax;
        uint256 price;
        uint256 activeAfterTimestamp;
        uint256 activeUntilTimestamp;
        uint256 nonce;
    }

    /**
     * @notice Encodes an approved allowance (i.e. signed by an authorised signer).
     */
    struct SignedAllowance {
        Allowance allowance;
        bytes signature;
    }

    /**
     * @notice Encodes the purchase data for the use in internal `Seller` hooks.
     */
    function encodePurchaseData(bytes32 digest_, SignedAllowance memory signedAllowance)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(digest_, signedAllowance);
    }

    /**
     * @notice Inverse of `_encodePurchaseData`.
     */
    function decodePurchaseData(bytes memory data) internal pure returns (bytes32, SignedAllowance memory) {
        return abi.decode(data, (bytes32, SignedAllowance));
    }

    /**
     * @notice Computes the hash of a given allowance depending on address and chainId of the seller contract.
     */
    function digest(Allowance memory allowance, uint256 chainId, address target) internal pure returns (bytes32) {
        // We do not use EIP712 signatures here for the time being for simplicity (and since we will be the only ones
        // signing).
        return ECDSA.toEthSignedMessageHash(
            abi.encode(
                allowance,
                // Adding chain id and the verifying contract address to prevent
                // replay attacks.
                chainId,
                target
            )
        );
    }
}

/**
 * @notice Introduces claimability based on signed allowances.
 */
abstract contract SignatureGated is Seller {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @notice Encodes a purchase with a signed allowance, partially consuming it.
     */
    struct SignedAllowancePurchase {
        SignatureGatedLib.SignedAllowance signedAllowance;
        uint64 num;
    }

    // =================================================================================================================
    //                           Errors
    // =================================================================================================================

    /**
     * @notice Thrown if there are too many requests for a given allowance.
     */
    error TooManyPurchasesRequested(SignatureGatedLib.Allowance, uint256 numLeft, uint256 numRequested);

    /**
     * @notice Thrown if a given allowance is not active.
     */
    error InactiveAllowance(SignatureGatedLib.Allowance);

    /**
     * @notice Thrown if a the signer of an allowance is not authorised.
     */
    error UnauthorisedSigner(SignatureGatedLib.SignedAllowance, address recovered);

    // =================================================================================================================
    //                           Storage
    // =================================================================================================================

    /**
     * @notice The set of autorised allowance signers.
     */
    EnumerableSet.AddressSet private _signers;

    /**
     * @notice Tracks how many purchases have been made with a signed allowance.
     */
    mapping(bytes32 => uint256) private _numPurchasesByAllowanceDigest;

    // =================================================================================================================
    //                           Purchasing
    // =================================================================================================================

    /**
     * @notice Computes the hash of a given allowance.
     * @dev This is the raw bytes32 message that will finally be signed by one of the authorised `_signers`.
     */
    function digest(SignatureGatedLib.Allowance memory allowance) public view returns (bytes32) {
        return SignatureGatedLib.digest(allowance, block.chainid, address(this));
    }

    /**
     * @notice Returns the number of purchases that have already been redeemed from a given allowance.
     */
    function numPurchasedWithAllowances(SignatureGatedLib.Allowance[] calldata allowances)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory nums = new uint[](allowances.length);
        for (uint256 i; i < allowances.length; ++i) {
            nums[i] = _numPurchasesByAllowanceDigest[digest(allowances[i])];
        }
        return nums;
    }

    /**
     * @notice Interface to perform purchases with signed allowances.
     * @dev Reverts if an allowances was incorrectly signed by an approved signed, is not active, or exhausted.
     */
    function purchase(SignedAllowancePurchase[] calldata purchases) public payable virtual {
        for (uint256 i; i < purchases.length; ++i) {
            _purchaseWithSignedAllowance(purchases[i]);
        }
    }

    /**
     * @notice Interface to perform a purchase with a signed allowance.
     * @dev Reverts if an allowances was incorrectly signed by an approved signed, is not active, or exhausted.
     */
    function _purchaseWithSignedAllowance(SignedAllowancePurchase calldata purchase_) internal virtual {
        // For clarity: Calling the virtual `_purchase` inherited from `Seller` here.
        _purchase(
            purchase_.signedAllowance.allowance.receiver,
            purchase_.num,
            purchase_.signedAllowance.allowance.price * purchase_.num,
            SignatureGatedLib.encodePurchaseData(digest(purchase_.signedAllowance.allowance), purchase_.signedAllowance)
        );
    }

    /**
     * @notice Validates a given purchase, i.e. signature validity and the number of purchases that have already been
     * performed.
     */
    function _checkAndModifyPurchase(address to, uint64 num, uint256 cost, bytes memory data)
        internal
        view
        virtual
        override
        returns (address, uint64, uint256)
    {
        (bytes32 digest_, SignatureGatedLib.SignedAllowance memory sa) = SignatureGatedLib.decodePurchaseData(data);

        // solhint-disable not-rely-on-time
        if (block.timestamp < sa.allowance.activeAfterTimestamp || block.timestamp >= sa.allowance.activeUntilTimestamp)
        {
            revert InactiveAllowance(sa.allowance);
        }
        // solhint-enable not-rely-on-time

        address signer = ECDSA.recover(digest_, sa.signature);
        if (!_signers.contains(signer)) {
            revert UnauthorisedSigner(sa, signer);
        }

        uint256 numLeft = sa.allowance.numMax - _numPurchasesByAllowanceDigest[digest_];
        if (numLeft < num) {
            revert TooManyPurchasesRequested(sa.allowance, numLeft, num);
        }

        return (to, num, cost);
    }

    /**
     * @inheritdoc Seller
     * @dev Updates the number of purchases that have already been performed with a given allowance.
     */
    function _beforePurchase(address, uint64 num, uint256, bytes memory data) internal virtual override {
        (bytes32 digest_,) = SignatureGatedLib.decodePurchaseData(data);
        _numPurchasesByAllowanceDigest[digest_] += num;
    }

    // =================================================================================================================
    //                           Steering
    // =================================================================================================================

    /**
     * @notice Changes set of signers authorised to sign allowances.
     */
    function _changeAllowlistSigners(address[] calldata rm, address[] calldata add) internal {
        for (uint256 i; i < rm.length; ++i) {
            _signers.remove(rm[i]);
        }
        for (uint256 i; i < add.length; ++i) {
            _signers.add(add[i]);
        }
    }
}
