// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.0 <0.9.0;

import "./IRedeemableToken.sol";

/**
 * @notice Base contract to redeem redeemable tokens.
 */
contract RedeemableTokenRedeemer {
    /**
     * @notice Redeems a redeemable token
     */
    function _redeem(IRedeemableToken redeemable, uint256 tokenId) internal {
        redeemable.redeem(msg.sender, tokenId);
    }
}
