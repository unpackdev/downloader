// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.19;

/**
 * @param nftIds The list of IDs of the NFTs to purchase
 * @param maxExpectedTokenInput The maximum acceptable cost from the sender (in wei or base units of ERC20).
 *   If the actual amount is greater than this value, the transaction will be reverted.
 * @param tokenSender ERC20 sender. Only used if msg.sender is an approved IDittoRouter, else msg.sender is used.
 * @param nftRecipient Address to send the purchased NFTs to.
 */
struct SwapTokensForNftsArgs {
    uint256[] nftIds;
    uint256 maxExpectedTokenInput;
    address tokenSender;
    address nftRecipient;
    bytes swapData;
}

/**
 * @param nftIds The list of IDs of the NFTs to sell to the pair
 * @param lpIds The list of IDs of the LP positions sell the NFTs to
 * @param minExpectedTokenOutput The minimum acceptable token count received by the sender. 
 *   If the actual amount is less than this value, the transaction will be reverted.
 * @param nftSender NFT sender. Only used if msg.sender is an approved IDittoRouter, else msg.sender is used.
 * @param tokenRecipient The recipient of the ERC20 proceeds.
 * @param permitterData Data to profe that the NFT Token IDs are permitted to be sold to this pool if a permitter is set.
 * @param swapData Extra data to pass to the curve
 */
struct SwapNftsForTokensArgs {
    uint256[] nftIds;
    uint256[] lpIds;
    uint256 minExpectedTokenOutput;
    address nftSender;
    address tokenRecipient;
    bytes permitterData;
    bytes swapData;
}

