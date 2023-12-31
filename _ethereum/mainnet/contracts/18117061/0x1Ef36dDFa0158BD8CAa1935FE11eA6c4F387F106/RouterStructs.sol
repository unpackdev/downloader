// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "./IDittoPool.sol";

/**
 * @notice Basic Struct used by DittoRouter For Specifying trades
 * @dev **pool** the pool to trade with
 * @dev **nftIds** which Nfts you wish to buy out of or sell into the pool
 */
struct Swap {
    IDittoPool pool;
    uint256[] nftIds;
    bytes swapData;
}

/**
 * @notice Struct used by DittoRouter when selling Nfts into a pool.
 * @dev **swapInfo** Swap info with pool and and Nfts being traded
 * @dev **lpIds** The LP Position TokenIds of the counterparties you wish to sell to in the pool
 * @dev **permitterData** Optional: data to pass to the pool for permission checks that the tokenIds are allowed in the pool
 */
struct NftInSwap {
    IDittoPool pool;
    uint256[] nftIds;
    uint256[] lpIds;
    bytes permitterData;
    bytes swapData;
}

/**
 * @notice Struct used for "robust" swaps that may have partial fills buying NFTs out of a pool
 * @dev **swapInfo** Swap info with pool and and Nfts being traded
 * @dev **maxCost** The maximum amount of tokens you are willing to pay for the Nfts total
 */
struct RobustSwap {
    IDittoPool pool;
    uint256[] nftIds;
    uint256 maxCost;
    bytes swapData;
}

/**
 * @notice Struct used for "robust" swaps that may have partial fills selling NFTs into a pool
 * @dev **nftSwapInfo** Swap info with pool, Nfts being traded, lp counterparties, and permitter data
 * @dev **minOutput** The total minimum amount of tokens you are willing to receive for the Nfts you sell, or abort
 */
struct RobustNftInSwap {
    IDittoPool pool;
    uint256[] nftIds;
    uint256[] lpIds;
    bytes permitterData;
    uint256 minOutput;
    bytes swapData;
}

/**
 * @notice DittoRouter struct for complex swaps with tokens bought and sold in one transaction
 * @dev **nftToTokenTrades** array of trade info where you are selling Nfts into pools
 * @dev **tokenToNftTrades** array of trade info where you are buying Nfts out of pools
 */
struct ComplexSwap {
    NftInSwap[] nftToTokenTrades;
    Swap[] tokenToNftTrades;
}

/**
 * @notice DittoRouter struct for robust partially-fillable complex swaps with tokens bought and sold in one transaction
 * @dev **nftToTokenTrades** array of trade info where you are selling Nfts into pools
 * @dev **tokenToNftTrades** array of trade info where you are buying Nfts out of pools
 * @dev **inputAmount** The total amount of tokens you are willing to spend on the Nfts you buy
 * @dev **tokenRecipient** The address to send the tokens to after the swap
 * @dev **nftRecipient** The address to send the Nfts to after the swap
 */
struct RobustComplexSwap {
    RobustSwap[] tokenToNftTrades;
    RobustNftInSwap[] nftToTokenTrades;
    uint256 inputAmount;
    address tokenRecipient;
    address nftRecipient;
    uint256 deadline;
}
