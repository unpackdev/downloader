// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./XNFTAdmin.sol";
import "./IXNFTClone.sol";

/// @title XNFT Mint Contract
/// @author Wilson A.
/// @notice Used for minting XNFTs
abstract contract XNFTMint is XNFTAdmin {
    modifier validAccountId(uint256 _accountId) {
        require(_accountId >= 1, "invalid account id");
        require(_accountId < accountId, "account not found");
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function _sendFees(address feeAddress, uint256 amount) internal {
        if (amount == 0) return;
        (bool success, ) = payable(feeAddress).call{value: amount}("");
        require(success, "fee transfer failed");
    }

    // --- Mint Functions --- //
    /**
     * @dev Mints multiple tokens for the caller, transferring them to their address and paying the minting fees.
     * @param _accountId The ID of the account associated with the tokens to be minted.
     * @param quantity The number of tokens to be minted.
     * @notice This function allows a user to mint multiple tokens associated with their account, paying the minting fees.
     * @dev Requirements:
     * - The current timestamp must be greater than or equal to the account's mint timestamp.
     * - The total number of minted tokens for the account (including the new ones) must not exceed the maximum allowed.
     * - The total number of tokens minted by the user for the account (including the new ones) must not exceed the maximum allowed per transaction.
     * - The caller must send the correct amount of Ether for minting.
     * - The contract must not be paused.
     */
    function mintMany(
        uint256 _accountId,
        uint32 quantity
    )
        external
        payable
        nonReentrant
        callerIsUser
        whenNotPaused
        validAccountId(_accountId)
    {
        require(quantity > 0, "quantity must be greater than zero");
        AccountInfo memory account = accounts[_accountId];
        AccountAddressInfo memory accountAddress = accountAddresses[_accountId];
        require(
            block.timestamp >= account.mintTimestamp,
            "mint timestamp not reached"
        );
        require(
            mintCount[_accountId] + quantity <= account.maxMintCount,
            "max mint count reached"
        );
        require(
            userMintCount[_accountId][msg.sender] + quantity <=
                account.maxMintPerWallet,
            "max user mint count reached"
        );
        uint256 totalPrice = account.mintPrice * quantity;
        IXNFTClone xnftClone = IXNFTClone(accountAddress.xnftCloneAddr);
        require(msg.value >= totalPrice, "insufficient funds");
        userMintCount[_accountId][msg.sender] += quantity;
        for (uint256 i; i < quantity; ) {
            xnftClone.mint(msg.sender, mintCount[_accountId]);
            unchecked {
                ++mintCount[_accountId];
                ++i;
            }
        }

        uint256 marketplaceFee = (totalPrice * marketplaceFeeBps) /
            FEE_DENOMINATOR;
        uint256 creatorFee = (totalPrice * creatorFeeBps) / FEE_DENOMINATOR;
        _sendFees(marketplaceFeeAddress, marketplaceFee);
        _sendFees(account.accountFeeAddress, creatorFee);
        _sendFees(
            accountAddress.xnftLPAddr,
            totalPrice - marketplaceFee - creatorFee
        );
        if (msg.value > totalPrice)
            _sendFees(msg.sender, msg.value - totalPrice);
    }
}
