// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

struct BoosterFuel {
    uint96 dubi;
    uint96 unlockedPrps;
    uint96 lockedPrps;
    uint96 intrinsicFuel;
}

struct BoosterPayload {
    address booster;
    uint64 timestamp;
    uint64 nonce;
    // Fallback for 'personal_sign' when e.g. using hardware wallets that don't support
    // EIP712 signing (yet).
    bool isLegacySignature;
}

// Library for Boostable hash functions that are completely inlined.
library BoostableLib {
    bytes32 private constant BOOSTER_PAYLOAD_TYPEHASH = keccak256(
        "BoosterPayload(address booster,uint64 timestamp,uint64 nonce,bool isLegacySignature)"
    );

    bytes32 internal constant BOOSTER_FUEL_TYPEHASH = keccak256(
        "BoosterFuel(uint96 dubi,uint96 unlockedPrps,uint96 lockedPrps,uint96 intrinsicFuel)"
    );

    /**
     * @dev Returns the hash of the packed DOMAIN_SEPARATOR and `messageHash` and is used for verifying
     * a signature.
     */
    function hashWithDomainSeparator(
        bytes32 domainSeparator,
        bytes32 messageHash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, messageHash)
            );
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
                    payload.nonce,
                    payload.isLegacySignature
                )
            );
    }

    function hashBoosterFuel(BoosterFuel memory fuel)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    BOOSTER_FUEL_TYPEHASH,
                    fuel.dubi,
                    fuel.unlockedPrps,
                    fuel.lockedPrps,
                    fuel.intrinsicFuel
                )
            );
    }

    /**
     * @dev Returns the tag found in the given `boosterMessage`.
     */
    function _readBoosterTag(bytes memory boosterMessage)
        internal
        pure
        returns (uint8)
    {
        // The tag is either the 32th byte or the 64th byte depending on whether
        // the booster message contains dynamic bytes or not.
        //
        // If it contains a dynamic byte array, then the first word points to the first
        // data location.
        //
        // Therefore, we read the 32th byte and check if it's >= 32 and if so,
        // simply read the (32 + first word)th byte to get the tag.
        //
        // This imposes a limit on the number of tags we can support (<32), but
        // given that it is very unlikely for so many tags to exist it is fine.
        //
        // Read the 32th byte to get the tag, because it is a uint8 padded to 32 bytes.
        // i.e.
        // -----------------------------------------------------------------v
        // 0x0000000000000000000000000000000000000000000000000000000000000001
        //   ...
        //
        uint8 tag = uint8(boosterMessage[31]);
        if (tag >= 32) {
            // Read the (32 + tag) byte. E.g. if tag is 32, then we read the 64th:
            // --------------------------------------------------------------------
            // 0x0000000000000000000000000000000000000000000000000000000000000020 |
            //   0000000000000000000000000000000000000000000000000000000000000001 <
            //   ...
            //
            tag = uint8(boosterMessage[31 + tag]);
        }

        return tag;
    }
}
