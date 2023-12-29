// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.0 <0.9.0;

import "./IRedeemableToken.sol";

/**
 * @notice Base contract to redeem redeemable tokens.
 */
contract RedeemableTokenRedeemer {
    /**
     * @notice Emitted when the callback to the `IRedeemableToken` contract fails.
     */
    error RedeemableCallbackFailed(IRedeemableToken token, uint256 tokenId, bytes reason);

    /**
     * @notice Redeems a redeemable token
     */
    function _redeem(IRedeemableToken redeemable, uint256 tokenId) internal {
        try redeemable.redeem(msg.sender, tokenId) {}
        catch (bytes memory reason) {
            revert RedeemableCallbackFailed(redeemable, tokenId, reason);
        }
    }
}
