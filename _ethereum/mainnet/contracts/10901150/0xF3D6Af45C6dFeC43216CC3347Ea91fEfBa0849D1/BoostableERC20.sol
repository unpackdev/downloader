// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./Boostable.sol";
import "./BoostableLib.sol";

/**
 * @dev EIP712 boostable primitives related to ERC20 for the Purpose domain
 */
abstract contract BoostableERC20 is Boostable {
    /**
     * @dev A struct representing the payload of the ERC20 `boostedSend` function.
     */
    struct BoostedSend {
        uint8 tag;
        address sender;
        address recipient;
        uint256 amount;
        bytes data;
        BoosterFuel fuel;
        BoosterPayload boosterPayload;
    }

    /**
     * @dev A struct representing the payload of the ERC20 `boostedBurn` function.
     */
    struct BoostedBurn {
        uint8 tag;
        address account;
        uint256 amount;
        bytes data;
        BoosterFuel fuel;
        BoosterPayload boosterPayload;
    }

    uint8 internal constant BOOST_TAG_SEND = 0;
    uint8 internal constant BOOST_TAG_BURN = 1;

    bytes32 internal constant BOOSTED_SEND_TYPEHASH = keccak256(
        "BoostedSend(uint8 tag,address sender,address recipient,uint256 amount,bytes data,BoosterFuel fuel,BoosterPayload boosterPayload)BoosterFuel(uint96 dubi,uint96 unlockedPrps,uint96 lockedPrps,uint96 intrinsicFuel)BoosterPayload(address booster,uint64 timestamp,uint64 nonce,bool isLegacySignature)"
    );

    bytes32 internal constant BOOSTED_BURN_TYPEHASH = keccak256(
        "BoostedBurn(uint8 tag,address account,uint256 amount,bytes data,BoosterFuel fuel,BoosterPayload boosterPayload)BoosterFuel(uint96 dubi,uint96 unlockedPrps,uint96 lockedPrps,uint96 intrinsicFuel)BoosterPayload(address booster,uint64 timestamp,uint64 nonce,bool isLegacySignature)"
    );

    constructor(address optIn) public Boostable(optIn) {}

    /**
     * @dev Returns the hash of `boostedSend`.
     */
    function hashBoostedSend(BoostedSend memory send, address booster)
        internal
        view
        returns (bytes32)
    {
        return
            BoostableLib.hashWithDomainSeparator(
                _DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        BOOSTED_SEND_TYPEHASH,
                        BOOST_TAG_SEND,
                        send.sender,
                        send.recipient,
                        send.amount,
                        keccak256(send.data),
                        BoostableLib.hashBoosterFuel(send.fuel),
                        BoostableLib.hashBoosterPayload(
                            send.boosterPayload,
                            booster
                        )
                    )
                )
            );
    }

    /**
     * @dev Returns the hash of `boostedBurn`.
     */
    function hashBoostedBurn(BoostedBurn memory burn, address booster)
        internal
        view
        returns (bytes32)
    {
        return
            BoostableLib.hashWithDomainSeparator(
                _DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        BOOSTED_BURN_TYPEHASH,
                        BOOST_TAG_BURN,
                        burn.account,
                        burn.amount,
                        keccak256(burn.data),
                        BoostableLib.hashBoosterFuel(burn.fuel),
                        BoostableLib.hashBoosterPayload(
                            burn.boosterPayload,
                            booster
                        )
                    )
                )
            );
    }

    /**
     * @dev Tries to interpret the given boosterMessage and
     * return it's hash plus creation timestamp.
     */
    function decodeAndHashBoosterMessage(
        address targetBooster,
        bytes memory boosterMessage
    ) external override view returns (bytes32, uint64) {
        require(boosterMessage.length > 0, "PB-7");

        uint8 tag = _readBoosterTag(boosterMessage);
        if (tag == BOOST_TAG_SEND) {
            BoostedSend memory send = abi.decode(boosterMessage, (BoostedSend));
            return (
                hashBoostedSend(send, targetBooster),
                send.boosterPayload.timestamp
            );
        }

        if (tag == BOOST_TAG_BURN) {
            BoostedBurn memory burn = abi.decode(boosterMessage, (BoostedBurn));
            return (
                hashBoostedBurn(burn, targetBooster),
                burn.boosterPayload.timestamp
            );
        }

        // Unknown tag, so just return an empty result
        return ("", 0);
    }
}
