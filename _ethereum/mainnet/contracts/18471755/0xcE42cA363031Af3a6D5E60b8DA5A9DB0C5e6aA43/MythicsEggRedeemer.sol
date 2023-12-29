// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.0 <0.9.0;

import "./IRedeemableToken.sol";
import "./MythicsV1.sol";
import "./MythicsEgg.sol";

import "./SellableCallbacker.sol";
import "./Seller.sol";
import "./RedeemableTokenRedeemer.sol";

/**
 * @notice Helper library to encode/decode the purchase payload sent to the Mythics seller interface.
 */
library MythicsEggRedemptionLib {
    struct PurchasePayload {
        uint256 eggId;
        MythicEggSampler.EggType eggType;
    }

    function encode(PurchasePayload[] memory redemptions) internal pure returns (bytes memory) {
        return abi.encode(redemptions);
    }

    function decode(bytes memory data) internal pure returns (PurchasePayload[] memory) {
        return abi.decode(data, (PurchasePayload[]));
    }
}

/**
 * @title Mythics: Egg redeemer
 * @notice Redeems activated mythic eggs for a Mythic (either a token in the case of a stone egg or an open choice for
 * non-stone eggs).
 * @author David Huber (@cxkoda)
 * @custom:reviewer Arran Schlosberg (@divergencearran)
 */
contract MythicsEggRedeemer is Seller, ImmutableSellableCallbacker, RedeemableTokenRedeemer {
    using MythicsEggRedemptionLib for MythicsEggRedemptionLib.PurchasePayload[];

    error EggNotActivated(uint256 eggId);
    error EggNotRevealed(uint256 eggId);

    MythicsEgg public immutable eggs;

    constructor(ISellable mythics, MythicsEgg eggs_) ImmutableSellableCallbacker(mythics) {
        eggs = eggs_;
    }

    /**
     * @notice Redeems the given passes and purchases pieces in the Diamond Exhibition.
     */
    function redeem(uint256[] calldata eggIds) external {
        MythicsEggRedemptionLib.PurchasePayload[] memory payloads =
            new MythicsEggRedemptionLib.PurchasePayload[](eggIds.length);

        for (uint256 i = 0; i < eggIds.length; ++i) {
            if (!eggs.activated(eggIds[i])) {
                revert EggNotActivated(eggIds[i]);
            }

            (MythicEggSampler.EggType eggType, bool revealed) = eggs.eggType(eggIds[i]);
            if (!revealed) {
                revert EggNotRevealed(eggIds[i]);
            }

            _redeem(eggs, eggIds[i]);
            payloads[i] = MythicsEggRedemptionLib.PurchasePayload({eggId: eggIds[i], eggType: eggType});
        }

        _purchase(msg.sender, uint64(eggIds.length), /* total cost */ 0, payloads.encode());
    }
}
