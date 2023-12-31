// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "./RouterStructs.sol";
import "./IERC721.sol";
import "./ERC20.sol";

/**
 * @title Ditto Swap Router Interface
 * @notice Performs swaps between Nfts and ERC20 tokens, across multiple pools, or more complicated multi-swap paths
 * @dev All swaps assume that a single ERC20 token is used for all the pools involved.
 * Swapping using multiple tokens in the same transaction is possible, but the slippage checks and the return values
 * will be meaningless, and may lead to undefined behavior.
 * @dev UX: The sender should grant infinite token approvals to the router in order for Nft-to-Nft swaps to work smoothly.
 * @dev This router has a notion of robust, and non-robust swaps. "Robust" versions of a swap will never revert due to
 * slippage. Instead, users specify a per-swap max cost. If the price changes more than the user specifies, no swap is
 * attempted. This allows users to specify a batch of swaps, and execute as many of them as possible.
 * On non-robust swaps, if any slippage check per trade fails in the chain, the entire transaction reverts.
 */
interface IDittoRouter {
    // ***************************************************************
    // * ============ TRADING ERC20 TOKENS FOR STUFF =============== *
    // ***************************************************************

    /**
     * @notice Swaps ERC20 tokens into specific Nfts using multiple pools.
     * @param swapList The list of pools to trade with and the IDs of the Nfts to buy from each.
     * @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-Nft swaps
     * @param nftRecipient The address that will receive the Nft output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent token amount
     */
    function swapTokensForNfts(
        Swap[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) external returns (uint256 remainingValue);

    /**
     * @notice Swaps as many ERC20 tokens for specific Nfts as possible, respecting the per-swap max cost.
     * @param swapList The list of pools to trade with and the IDs of the Nfts to buy from each.
     * @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-Nft swaps
     *
     * @param nftRecipient The address that will receive the Nft output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent token amount
     */
    function robustSwapTokensForNfts(
        RobustSwap[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) external returns (uint256 remainingValue);

    /**
     * @notice Buys Nfts with ERC20, and sells them for tokens in one transaction
     * @param params All the parameters for the swap (packed in struct to avoid stack too deep), containing:
     * - ethToNftSwapList The list of Nfts to buy
     * - nftToTokenSwapList The list of Nfts to sell
     * - inputAmount The max amount of tokens to send (if ERC20)
     * - tokenRecipient The address that receives tokens from the Nfts sold
     * - nftRecipient The address that receives Nfts
     * - deadline UNIX timestamp deadline for the swap
     */
    function robustSwapTokensForNftsAndNftsForTokens(RobustComplexSwap calldata params)
        external
        returns (uint256 remainingValue, uint256 outputAmount);

    // ***************************************************************
    // * ================= TRADING NFTs FOR STUFF ================== *
    // ***************************************************************

    /**
     * @notice Swaps Nfts into ETH/ERC20 using multiple pools.
     * @param swapList The list of pools to trade with and the IDs of the Nfts to sell to each.
     * @param minOutput The minimum acceptable total tokens received
     * @param tokenRecipient The address that will receive the token output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return outputAmount The total tokens received
     */
    function swapNftsForTokens(
        NftInSwap[] calldata swapList,
        uint256 minOutput,
        address tokenRecipient,
        uint256 deadline
    ) external returns (uint256 outputAmount);

    /**
     * @notice Swaps as many Nfts for tokens as possible, respecting the per-swap min output
     * @param swapList The list of pools to trade with and the IDs of the Nfts to sell to each.
     * @param tokenRecipient The address that will receive the token output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return outputAmount The total ETH/ERC20 received
     */
    function robustSwapNftsForTokens(
        RobustNftInSwap[] calldata swapList,
        address tokenRecipient,
        uint256 deadline
    ) external returns (uint256 outputAmount);

    /**
     * @notice Swaps one set of Nfts into another set of specific Nfts using multiple pools, using
     * an ERC20 token as the intermediary.
     * @param trade The struct containing all Nft-to-ERC20 swaps and ERC20-to-Nft swaps.
     * @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-Nft swaps
     * @param minOutput The minimum acceptable total excess tokens received
     * @param nftRecipient The address that will receive the Nft output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return outputAmount The total ERC20 tokens received
     */
    function swapNftsForSpecificNftsThroughTokens(
        ComplexSwap calldata trade,
        uint256 inputAmount,
        uint256 minOutput,
        address nftRecipient,
        uint256 deadline
    ) external returns (uint256 outputAmount);

    // ***************************************************************
    // * ================= RESTRICTED FUNCTIONS ==================== *
    // ***************************************************************

    /**
     * @notice Allows pool contracts to transfer ERC20 tokens directly from
     * the sender, in order to minimize the number of token transfers.
     * @dev Only callable by valid IDittoPools.
     * @param token The ERC20 token to transfer
     * @param from The address to transfer tokens from
     * @param to The address to transfer tokens to
     * @param amount The amount of tokens to transfer
     */
    function poolTransferErc20From(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) external;

    /**
     * @notice Allows pool contracts to transfer ERC721 NFTs directly from
     * the sender, in order to minimize the number of token transfers.
     * @dev Only callable by valid IDittoPools.
     * @param nft The ERC721 NFT to transfer
     * @param from The address to transfer tokens from
     * @param to The address to transfer tokens to
     * @param id The ID of the NFT to transfer
     */
    function poolTransferNftFrom(IERC721 nft, address from, address to, uint256 id) external;
}
