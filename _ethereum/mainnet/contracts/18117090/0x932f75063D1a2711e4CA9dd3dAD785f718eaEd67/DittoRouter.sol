// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "./IDittoRouter.sol";
import "./RouterStructs.sol";
import "./SwapArgs.sol";

import "./ERC20.sol";
import "./IDittoPool.sol";
import "./ILpNft.sol";
import "./CurveErrorCode.sol";

import "./IERC721.sol";
import { ReentrancyGuard } from
    "../../../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "./SafeTransferLib.sol";

contract DittoRouter is IDittoRouter, ReentrancyGuard {
    using SafeTransferLib for ERC20;

    ILpNft internal immutable _lpNft;

    modifier checkDeadline(uint256 deadline) {
        _checkDeadline(deadline);
        _;
    }

    // ***************************************************************
    // * ========================= ERRORS ========================== *
    // ***************************************************************

    error DittoRouterDeadlinePassed();
    error DittoRouterOutputAmountTooLow();
    error DittoRouterNotApprovedPool();

    constructor(ILpNft lpNft_) {
        _lpNft = lpNft_;
    }

    // ***************************************************************
    // * ============ TRADING ERC20 TOKENS FOR STUFF =============== *
    // ***************************************************************

    ///@inheritdoc IDittoRouter
    function swapTokensForNfts(
        Swap[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) external virtual nonReentrant checkDeadline(deadline) returns (uint256 remainingValue) {
        remainingValue = _swapTokensForNfts(swapList, inputAmount, nftRecipient);
    }

    ///@inheritdoc IDittoRouter
    function robustSwapTokensForNfts(
        RobustSwap[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) public virtual nonReentrant checkDeadline(deadline) returns (uint256 remainingValue) {
        remainingValue = _robustSwapTokensForNfts(swapList, inputAmount, nftRecipient);
    }

    ///@inheritdoc IDittoRouter
    function robustSwapTokensForNftsAndNftsForTokens(RobustComplexSwap calldata params)
        external
        virtual
        nonReentrant
        returns (uint256 remainingValue, uint256 outputAmount)
    {
        remainingValue = _robustSwapTokensForNfts(
            params.tokenToNftTrades, params.inputAmount, params.nftRecipient
        );
        outputAmount = _robustSwapNftsForTokens(params.nftToTokenTrades, params.tokenRecipient);
    }

    // ***************************************************************
    // * ================= TRADING NFTs FOR STUFF ================== *
    // ***************************************************************

    ///@inheritdoc IDittoRouter
    function swapNftsForTokens(
        NftInSwap[] calldata swapList,
        uint256 minOutput,
        address tokenRecipient,
        uint256 deadline
    ) external virtual nonReentrant checkDeadline(deadline) returns (uint256 outputAmount) {
        outputAmount = _swapNftsForTokens(swapList, minOutput, tokenRecipient);
    }

    ///@inheritdoc IDittoRouter
    function robustSwapNftsForTokens(
        RobustNftInSwap[] calldata swapList,
        address tokenRecipient,
        uint256 deadline
    ) public virtual nonReentrant checkDeadline(deadline) returns (uint256 outputAmount) {
        outputAmount = _robustSwapNftsForTokens(swapList, tokenRecipient);
    }

    ///@inheritdoc IDittoRouter
    function swapNftsForSpecificNftsThroughTokens(
        ComplexSwap calldata trade,
        uint256 inputAmount,
        uint256 minOutput,
        address nftRecipient,
        uint256 deadline
    ) external virtual nonReentrant checkDeadline(deadline) returns (uint256 outputAmount) {
        // Swap Nfts for ERC20
        // minOutput of swap set to 0 since we're doing an aggregate slippage check
        // output tokens are sent to msg.sender
        outputAmount = _swapNftsForTokens(trade.nftToTokenTrades, 0, msg.sender);

        // Add extra value to buy Nfts
        outputAmount += inputAmount;

        // Swap ERC20 for specific Nfts
        // cost <= maxCost = outputAmount - minOutput, so outputAmount' = outputAmount - cost >= minOutput
        // input tokens are taken directly from msg.sender
        outputAmount = _swapTokensForNfts(
            trade.tokenToNftTrades, outputAmount - minOutput, nftRecipient
        ) + minOutput;
    }

    // ***************************************************************
    // * ================= RESTRICTED FUNCTIONS ==================== *
    // ***************************************************************

    ///@inheritdoc IDittoRouter
    function poolTransferErc20From(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) external virtual {
        // verify caller is a trusted pool contract
        _checkIsApprovedPool();

        // transfer tokens to pool
        token.safeTransferFrom(from, to, amount);
    }

    ///@inheritdoc IDittoRouter
    function poolTransferNftFrom(IERC721 nft, address from, address to, uint256 id) external {
        _checkIsApprovedPool();

        // transfer NFTs to pool
        nft.transferFrom(from, to, id);
    }

    // ***************************************************************
    // * ================= INTERNAL FUNCTIONS ====================== *
    // ***************************************************************

    /**
     * @notice Used to ensure the deadline has not passed before swapping
     * @param deadline The last valid time for a swap
     */
    function _checkDeadline(uint256 deadline) internal view {
        if (block.timestamp > deadline) {
            revert DittoRouterDeadlinePassed();
        }
    }

    /**
     * @notice Used to check if the caller is an approved pool
     */
    function _checkIsApprovedPool() internal view {
        if (!_lpNft.isApprovedDittoPool(msg.sender)) {
            revert DittoRouterNotApprovedPool();
        }
    }

    /**
     * @notice Internal function used to swap an ERC20 token for specific Nfts
     * @dev Note that we don't need to query the pool's bonding curve first for pricing data because
     *   we just calculate and take the required amount from the caller during swap time.
     * 
     * @param swapList The list of pools and swap calldata
     * @param inputAmount The total amount of ERC20 tokens to send
     * @param nftRecipient The address receiving the Nfts from the pools
     * @return remainingValue The unspent token amount
     */
    function _swapTokensForNfts(
        Swap[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient
    ) internal virtual returns (uint256 remainingValue) {
        remainingValue = inputAmount;

        // Do swaps
        uint256 numSwaps = swapList.length;
        Swap memory swap;
        for (uint256 i; i < numSwaps;) {
            // Tokens are transferred in by the pool calling router.poolTransferERC20From
            // Total tokens taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            swap = swapList[i];
            remainingValue -= swap.pool.swapTokensForNfts(
                SwapTokensForNftsArgs({
                    nftIds: swap.nftIds, 
                    maxExpectedTokenInput: remainingValue, 
                    tokenSender: msg.sender, 
                    nftRecipient: nftRecipient, 
                    swapData: swap.swapData
                })
            );
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Internal swapping function for robust Token to NFT swaps
     * @param swapList The list of pools and swap calldata
     * @param inputAmount The acceptable total amount of ERC20 tokens to not exceed sending
     * @param nftRecipient The address receiving the Nfts from the pools
     */
    function _robustSwapTokensForNfts(
        RobustSwap[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient
    ) internal virtual returns (uint256 remainingValue) {
        remainingValue = inputAmount;
        uint256 poolCost;
        CurveErrorCode cError;

        // Try doing each swap
        uint256 numSwaps = swapList.length;
        RobustSwap memory swap;
        for (uint256 i; i < numSwaps;) {
            swap = swapList[i];
            // Calculate actual cost per swap
            (cError,,, poolCost,) = swap.pool.getBuyNftQuote(swap.nftIds.length, swap.swapData);

            // If within our maxCost and no error, proceed
            if (cError == CurveErrorCode.OK && poolCost <= swap.maxCost) {
                remainingValue -= swap.pool.swapTokensForNfts(
                    SwapTokensForNftsArgs({
                        nftIds: swap.nftIds, 
                        maxExpectedTokenInput: poolCost, 
                        tokenSender: msg.sender, 
                        nftRecipient: nftRecipient, 
                        swapData: swap.swapData
                    })
                );
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Swaps Nfts for tokens, designed to be used for 1 token at a time
     * @dev Calling with multiple tokens is permitted, BUT minOutput will be
     * far from enough of a safety check because different tokens almost certainly have different unit prices.
     * @param swapList The list of pools and swap calldata
     * @param minOutput The minimum number of tokens to be receieved from the swaps
     * @param tokenRecipient The address that receives the tokens
     * @return outputAmount The number of tokens to be received
     */
    function _swapNftsForTokens(
        NftInSwap[] calldata swapList,
        uint256 minOutput,
        address tokenRecipient
    ) internal virtual returns (uint256 outputAmount) {
        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Do the swap for token and then update outputAmount
            // Note: minExpectedTokenOutput is set to 0 since we're doing an aggregate slippage check below
            NftInSwap memory swap = swapList[i];
            outputAmount += swap.pool.swapNftsForTokens(
                SwapNftsForTokensArgs({
                    nftIds: swap.nftIds,
                    lpIds: swap.lpIds,
                    minExpectedTokenOutput: 0,
                    nftSender: msg.sender,
                    tokenRecipient: tokenRecipient,
                    permitterData: swap.permitterData,
                    swapData: swap.swapData
                })
            );

            unchecked {
                ++i;
            }
        }

        // Aggregate slippage check
        if (outputAmount < minOutput) {
            revert DittoRouterOutputAmountTooLow();
        }
    }

    /**
     * @notice Internal swapping function for robust NFT to Token swaps
     * @param swapList The list of pools and swap calldata
     * @param tokenRecipient The address that receives the tokens
     * @return outputAmount The number of tokens to be received
     */
    function _robustSwapNftsForTokens(
        RobustNftInSwap[] calldata swapList,
        address tokenRecipient
    ) internal virtual returns (uint256 outputAmount) {
        // Try doing each swap
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Locally scoped to avoid stack too deep error

            outputAmount += _robustSwapNftsForTokensIteration(swapList[i], tokenRecipient);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Gets the sell quote for a pool, but throws away the unneeded data
     * @dev Avoiding stack too deep errors
     * @param pool The pool to query
     * @param numNftsToSell The number of Nfts to sell
     * @return cError The error code
     * @return poolOutput The amount of tokens that would be received
     */
    function _getSellQuoteThrowAwayUnneeded(
        IDittoPool pool,
        uint256 numNftsToSell,
        bytes calldata swapData
    ) internal view returns (CurveErrorCode cError, uint256 poolOutput) {
        (cError,,, poolOutput,) = pool.getSellNftQuote(numNftsToSell, swapData);
    }

    /**
     * @notice see IDittoRouter.robustSwapNftsForTokens: this is an internal function to avoid stack too deep errors
     * @param swap The swap to perform
     * @param tokenRecipient The address that receives the tokens
     * @return outputAmount The number of tokens that the recipient will get, or zero if the swap does not meet conditions
     */
    function _robustSwapNftsForTokensIteration(
        RobustNftInSwap calldata swap,
        address tokenRecipient
    ) internal virtual returns (uint256 outputAmount) {
        (CurveErrorCode cError, uint256 poolOutput) = _getSellQuoteThrowAwayUnneeded(
            swap.pool, 
            swap.nftIds.length, 
            swap.swapData
        );

        // If at least equal to our minOutput, proceed
        if (cError == CurveErrorCode.OK && poolOutput >= swap.minOutput) {
            // Do the swap and update outputAmount with how many tokens we got
            outputAmount = swap.pool.swapNftsForTokens(
                SwapNftsForTokensArgs({
                    nftIds: swap.nftIds,
                    lpIds: swap.lpIds,
                    minExpectedTokenOutput: 0,
                    nftSender: msg.sender,
                    tokenRecipient: tokenRecipient,
                    permitterData: swap.permitterData,
                    swapData: swap.swapData
                })
            );
        }
    }
}
