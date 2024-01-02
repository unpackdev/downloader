// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./XNFTMint.sol";
import "./IXNFTLiquidityPool.sol";

/// @title XNFT AssetManager Contract
/// @author Wilson A.
/// @notice Used for claiming and redemption of liquidity
abstract contract XNFTAssetManager is XNFTMint {
    // --- Redeem Functions --- //
    /**
     * @dev Redeems a token for the caller, transferring it to their address and paying the redemption fee.
     * @param _accountId The ID of the account associated with the token.
     * @param tokenId The ID of the token to be redeemed.
     * @notice This function allows a user to redeem a token associated with their account, paying the redemption fee.
     * @dev Requirements:
     * - The caller must be the owner of the token.
     * - The caller must be an EOA.
     * - The account must have tokens available for redemption.
     * - The contract must not be paused.
     */
    function redeem(
        uint256 _accountId,
        uint256 tokenId
    )
        external
        nonReentrant
        callerIsUser
        whenNotPaused
        validAccountId(_accountId)
    {
        require(
            accounts[_accountId].mintPrice > 0,
            "redemption not available during 0 price minting"
        );
        IXNFTLiquidityPool xnftLP = IXNFTLiquidityPool(
            accountAddresses[_accountId].xnftLPAddr
        );
        xnftLP.redeem(msg.sender, tokenId);
    }

    /**
     * @dev Claims a token, transferring it to the caller's address and paying the required amount.
     * @param _accountId The ID of the account associated with the token.
     * @param tokenId The ID of the token to be claimed.
     * @notice This function allows a user to claim a token associated with their account, paying the claim fee.
     * @dev Requirements:
     * - The token must be eligible for claiming (previously redeemed).
     * - The caller must be an EOA.
     * - The caller must send the correct amount of Ether for claiming.
     * - The contract must not be paused.
     */
    function claim(
        uint256 _accountId,
        uint256 tokenId
    )
        external
        payable
        nonReentrant
        callerIsUser
        whenNotPaused
        validAccountId(_accountId)
    {
        IXNFTLiquidityPool xnftLP = IXNFTLiquidityPool(
            accountAddresses[_accountId].xnftLPAddr
        );
        xnftLP.claim{value: msg.value}(msg.sender, tokenId);
    }

    function _accountTvl(
        uint256 _accountId
    ) internal view validAccountId(_accountId) returns (uint256) {
        IXNFTLiquidityPool xnftLP = IXNFTLiquidityPool(
            accountAddresses[_accountId].xnftLPAddr
        );
        return xnftLP.accountTvl();
    }

    /**
     * @dev Calculates the redemption price for a specific account.
     * @param _accountId The ID of the account.
     * @return uint256 The redemption price.
     * @notice This function calculates the redemption price for an account's tokens based on the available assets.
     * If all tokens have been redeemed, the redemption price is 0.
     */
    function redeemPrice(uint256 _accountId) public view returns (uint256) {
        IXNFTLiquidityPool xnftLP = IXNFTLiquidityPool(
            accountAddresses[_accountId].xnftLPAddr
        );
        return xnftLP.redeemPrice();
    }
}
