// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./ECDSA.sol";
import "./IOptIn.sol";
import "./BoostableLib.sol";
import "./IBoostableERC20.sol";

/**
 * @dev Boostable base contract
 *
 * All deriving contracts are expected to implement EIP712 for the message signing.
 *
 */
abstract contract EIP712Boostable {
    using ECDSA for bytes32;

    // solhint-disable-next-line var-name-mixedcase
    IOptIn internal immutable _OPT_IN;
    // solhint-disable-next-line var-name-mixedcase
    bytes32 internal immutable _DOMAIN_SEPARATOR;

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    bytes32 private constant BOOSTER_PAYLOAD_TYPEHASH = keccak256(
        "BoosterPayload(address booster,uint64 timestamp,uint64 nonce,bool isLegacySignature)"
    );

    bytes32 internal constant BOOSTER_FUEL_TYPEHASH = keccak256(
        "BoosterFuel(uint96 dubi,uint96 unlockedPrps,uint96 lockedPrps,uint96 intrinsicFuel)"
    );

    // The boost fuel is capped to 10 of the respective token that will be used for payment.
    uint96 internal constant MAX_BOOSTER_FUEL = 10 ether;

    // A magic booster permission prefix
    bytes6 private constant MAGIC_BOOSTER_PERMISSION_PREFIX = "BOOST-";

    constructor(address optIn, bytes32 domainSeparator) public {
        _OPT_IN = IOptIn(optIn);
        _DOMAIN_SEPARATOR = domainSeparator;
    }

    // A mapping of mappings to keep track of used nonces by address to
    // protect against replays. Each 'Boostable' contract maintains it's own
    // state for nonces.
    mapping(address => uint64) private _nonces;

    //---------------------------------------------------------------

    function getNonce(address account) external virtual view returns (uint64) {
        return _nonces[account];
    }

    function getOptInStatus(address account)
        internal
        view
        returns (IOptIn.OptInStatus memory)
    {
        return _OPT_IN.getOptInStatus(account);
    }

    /**
     * @dev Called by every 'boosted'-function to ensure that `msg.sender` (i.e. a booster) is
     * allowed to perform the call for `from` (the origin) by verifying that `messageHash`
     * has been signed by `from`. Additionally, `from` provides a nonce to prevent
     * replays. Boosts cannot be verified out of order.
     *
     * @param from the address that the boost is made for
     * @param messageHash the reconstructed message hash based on the function input
     * @param payload the booster payload
     * @param signature the signature of `from`
     */
    function verifyBoost(
        address from,
        bytes32 messageHash,
        BoosterPayload memory payload,
        Signature memory signature
    ) internal {
        uint64 currentNonce = _nonces[from];
        require(currentNonce == payload.nonce - 1, "AB-1");

        _nonces[from] = currentNonce + 1;

        _verifyBoostWithoutNonce(from, messageHash, payload, signature);
    }

    /**
     * @dev Verify a boost without verifying the nonce.
     */
    function _verifyBoostWithoutNonce(
        address from,
        bytes32 messageHash,
        BoosterPayload memory payload,
        Signature memory signature
    ) internal view {
        // The sender must be the booster specified in the payload
        require(msg.sender == payload.booster, "AB-2");

        (bool isOptedInToSender, uint256 optOutPeriod) = _OPT_IN.isOptedInBy(
            msg.sender,
            from
        );

        // `from` must be opted-in to booster
        require(isOptedInToSender, "AB-3");

        // The given timestamp must not be greater than `block.timestamp + 1 hour`
        // and at most `optOutPeriod(booster)` seconds old.
        uint64 _now = uint64(block.timestamp);
        uint64 _optOutPeriod = uint64(optOutPeriod);

        bool notTooFarInFuture = payload.timestamp <= _now + 1 hours;
        bool belowMaxAge = true;

        // Calculate the absolute difference. Because of the small tolerance, `payload.timestamp`
        // may be greater than `_now`:
        if (payload.timestamp <= _now) {
            belowMaxAge = _now - payload.timestamp <= _optOutPeriod;
        }

        // Signature must not be expired
        require(notTooFarInFuture && belowMaxAge, "AB-4");

        // NOTE: Currently, hardware wallets (e.g. Ledger, Trezor) do not support EIP712 signing (specifically `signTypedData_v4`).
        // However, a user can still sign the EIP712 hash with the caveat that it's signed using `personal_sign` which prepends
        // the prefix '"\x19Ethereum Signed Message:\n" + len(message)'.
        //
        // To still support that, we add the prefix to the hash if `isLegacySignature` is true.
        if (payload.isLegacySignature) {
            messageHash = messageHash.toEthSignedMessageHash();
        }

        // Valid, if the recovered address from `messageHash` with the given `signature` matches `from`.

        address signer = ecrecover(
            messageHash,
            signature.v,
            signature.r,
            signature.s
        );

        if (!payload.isLegacySignature && signer != from) {
            // As a last resort we try anyway, in case the caller simply forgot the `isLegacySignature` flag.
            signer = ecrecover(
                messageHash.toEthSignedMessageHash(),
                signature.v,
                signature.r,
                signature.s
            );
        }

        require(from == signer, "AB-5");
    }

    /**
     * @dev Returns the hash of `payload` using the provided booster (i.e. `msg.sender`).
     */
    function hashBoosterPayload(BoosterPayload memory payload, address booster)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    BOOSTER_PAYLOAD_TYPEHASH,
                    booster,
                    payload.timestamp,
                    payload.nonce
                )
            );
    }

    function _getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}
