// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.15;

import "./RedeemableERC721ACommon.sol";

/**
 * @title MintPassBurner
 * @dev This contract allows anyone to burn mint passes and must therefore be used with caution.
 */
contract MintPassBurner {
    RedeemableERC721ACommon internal immutable _redeemable;

    constructor(RedeemableERC721ACommon redeemable) {
        _redeemable = redeemable;
    }

    function burn(uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length; i++) {
            // Intentionally using `ownerOf` instead of `msg.sender` to burn all tokens after granting this redeemer the
            // REDEEMER_ROLE on `_redeemable`.
            _redeemable.redeem(_redeemable.ownerOf(tokenIds[i]), tokenIds[i]);
        }
    }
}
