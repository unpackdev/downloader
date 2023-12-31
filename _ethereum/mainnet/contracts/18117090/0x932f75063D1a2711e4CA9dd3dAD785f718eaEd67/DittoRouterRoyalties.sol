// SPDX-License-Identifier: AGPL-3.0
// Forked from Sudoswap & Defi Wonderland https://defi.sucks also under AGPL-3.0
pragma solidity 0.8.19;

import "./CurveErrorCode.sol";
import "./RouterStructs.sol";
import "./SwapArgs.sol";
import "./DittoRouter.sol";
import "./IDittoRouter.sol";
import "./IDittoPool.sol";
import "./ILpNft.sol";

import "./IERC2981.sol";
import "./IRoyaltyRegistry.sol";
import "./ERC20.sol";
import "./SafeTransferLib.sol";

contract DittoRouterRoyalties is DittoRouter {
    using SafeTransferLib for ERC20;

    // ***************************************************************
    // * ========================= EVENTS ========================== *
    // ***************************************************************

    event DittoRouterRoyaltiesRoyaltyIssued(
        address issuer, address pool, address recipient, uint256 salePrice, uint256 royaltyAmount
    );

    // ***************************************************************
    // * ========================= ERRORS ========================== *
    // ***************************************************************

    error DittoRoyaltyRouterNotImplemented();
    error DittoRoyaltyRouterOutputAmountTooLow();
    error DittoRoyaltyRouterRoyaltyExceedsSalePrice();

    IRoyaltyRegistry public immutable ROYALTY_REGISTRY; 

    uint256 public immutable FETCH_TOKEN_ID;

    constructor(ILpNft lpNft_, address royaltyRegistry) DittoRouter(lpNft_) {
        ROYALTY_REGISTRY = IRoyaltyRegistry(royaltyRegistry);

        // used to query the default royalty for a NFT collection
        // allows collection owner to set a particular royalty for this router
        FETCH_TOKEN_ID = uint256(keccak256(abi.encode(address(this))));
    }

    /**
     * @notice Helper function to check if a collection supports royalties
     * @param collection what NFT contract address to check
     * @return collectionSupportsRoyalty whether or not the collection supports royalties
     */
    function supportsRoyalty(address collection)
        external
        view
        returns (bool collectionSupportsRoyalty)
    {
        (, collectionSupportsRoyalty) = _getRoyaltyStatus(collection);
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
    )
        external
        virtual
        override
        nonReentrant
        checkDeadline(deadline)
        returns (uint256 remainingValue)
    {
        remainingValue = _swapTokensForNfts(swapList, inputAmount, nftRecipient);
    }

    ///@inheritdoc IDittoRouter
    function robustSwapTokensForNfts(
        RobustSwap[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    )
        public
        virtual
        override
        nonReentrant
        checkDeadline(deadline)
        returns (uint256 remainingValue)
    {
        remainingValue = _robustSwapTokensForNfts(swapList, inputAmount, nftRecipient);
    }

    ///@inheritdoc IDittoRouter
    function robustSwapTokensForNftsAndNftsForTokens(RobustComplexSwap calldata params)
        external
        virtual
        override
        nonReentrant
        checkDeadline(params.deadline)
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
    ///@dev not implemented on RoyaltyRouter
    function swapNftsForTokens(
        NftInSwap[] calldata swapList,
        uint256 minOutput,
        address tokenRecipient,
        uint256 deadline
    )
        external
        virtual
        override
        nonReentrant
        checkDeadline(deadline)
        returns (uint256 outputAmount)
    {
        outputAmount = _swapNftsForTokens(swapList, minOutput, tokenRecipient);
    }

    ///@inheritdoc IDittoRouter
    function robustSwapNftsForTokens(
        RobustNftInSwap[] calldata swapList,
        address tokenRecipient,
        uint256 deadline
    ) public virtual override nonReentrant checkDeadline(deadline) returns (uint256 outputAmount) {
        outputAmount = _robustSwapNftsForTokens(swapList, tokenRecipient);
    }

    ///@inheritdoc IDittoRouter
    ///@dev not implemented on RoyaltyRouter
    function swapNftsForSpecificNftsThroughTokens(
        ComplexSwap calldata, /*trade*/
        uint256, /*inputAmount*/
        uint256, /*minOutput*/
        address, /*nftRecipient*/
        uint256 /*deadline*/
    ) external virtual override returns (uint256 /*outputAmount*/ ) {
        revert DittoRoyaltyRouterNotImplemented();
    }

    // ***************************************************************
    // * =============== PUBLIC VIEW FUNCTIONS ===================== *
    // ***************************************************************
    function calculateRoyalties(
        address nftCollection,
        uint256 salePrice
    ) public view returns (address recipient, uint256 royalties) {
        (address lookupAddress, bool collectionSupportsRoyalty) =
            _getRoyaltyStatus(nftCollection);

        // calculates royalty payments for ERC2981 compatible lookup addresses
        if (collectionSupportsRoyalty) {
            // queries the default royalty (or specific for this router)
            (recipient, royalties) = IERC2981(lookupAddress).royaltyInfo(FETCH_TOKEN_ID, salePrice);
        }
    }

    // ***************************************************************
    // * ================= INTERNAL FUNCTIONS ====================== *
    // ***************************************************************

    ///@inheritdoc DittoRouter
    function _swapTokensForNfts(
        Swap[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient
    ) internal virtual override returns (uint256 remainingValue) {
        remainingValue = inputAmount;
        uint256 poolCost;

        // Do swaps
        uint256 numSwaps = swapList.length;
        Swap calldata swap;
        IDittoPool pool;
        for (uint256 i; i < numSwaps;) {
            swap = swapList[i];
            pool = swap.pool;

            // Tokens are transferred in by the pool calling router.poolTransferERC20From
            // Total tokens taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            poolCost =
                pool.swapTokensForNfts(
                    SwapTokensForNftsArgs({
                        nftIds: swap.nftIds, 
                        maxExpectedTokenInput: remainingValue, 
                        tokenSender: msg.sender, 
                        nftRecipient: nftRecipient, 
                        swapData: swap.swapData
                    })
                );

            ERC20 token = ERC20(pool.token());
            remainingValue -= poolCost + _calculateAndIssueTokenRoyalties(pool, token, poolCost);

            unchecked {
                ++i;
            }
        }
    }

    ///@inheritdoc DittoRouter
    function _robustSwapTokensForNfts(
        RobustSwap[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient
    ) internal override returns (uint256 remainingValue) {
        remainingValue = inputAmount;
        uint256 poolCost;

        // Try doing each swap
        uint256 numSwaps = swapList.length;
        RobustSwap calldata swap;
        IDittoPool pool;
        for (uint256 i; i < numSwaps;) {
            swap = swapList[i];
            pool = swap.pool;

            // Locally scoped to avoid stack too deep error
            {
                CurveErrorCode cError;
                // Calculate actual cost per swap
                (cError,,, poolCost,) = pool.getBuyNftQuote(swap.nftIds.length, swap.swapData);
                if (cError != CurveErrorCode.OK) {
                    unchecked {
                        ++i;
                    }
                    continue;
                }
            }

            (address royaltyRecipient, uint256 royaltyAmount) = _calculateRoyalties(pool, poolCost);

            // If within our maxCost and no error, proceed
            if (poolCost + royaltyAmount <= swap.maxCost) {
                poolCost = pool.swapTokensForNfts(SwapTokensForNftsArgs({
                    nftIds: swap.nftIds,
                    maxExpectedTokenInput: poolCost, 
                    tokenSender: msg.sender, 
                    nftRecipient: nftRecipient,
                    swapData: swap.swapData
                }));

                remainingValue -= poolCost;

                if (royaltyAmount > 0) {
                    remainingValue -= royaltyAmount;
                    ERC20 token = ERC20(pool.token());
                    token.safeTransferFrom(msg.sender, royaltyRecipient, royaltyAmount);
                    emit DittoRouterRoyaltiesRoyaltyIssued(
                        msg.sender, address(pool), royaltyRecipient, poolCost, royaltyAmount
                    );
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    ///@inheritdoc DittoRouter
    function _swapNftsForTokens(
        NftInSwap[] calldata swapList,
        uint256 minOutput,
        address tokenRecipient
    ) internal virtual override returns (uint256 outputAmount) {
        // Do swaps
        uint256 swapOutputAmount;
        uint256 numSwaps = swapList.length;
        NftInSwap calldata swap;
        IDittoPool pool;
        for (uint256 i; i < numSwaps;) {
            swap = swapList[i];
            pool = swap.pool;

            // Do the swap for token and then update outputAmount
            // Note: minExpectedTokenOutput is set to 0 since we're doing an aggregate slippage check below
            swapOutputAmount = pool.swapNftsForTokens(
                SwapNftsForTokensArgs({
                    nftIds: swap.nftIds,
                    lpIds: swap.lpIds,
                    minExpectedTokenOutput: 0,
                    nftSender: msg.sender,
                    tokenRecipient: payable(address(this)),
                    permitterData: swap.permitterData,
                    swapData: swap.swapData
                })
            );

            ERC20 token = ERC20(pool.token());

            (address royaltyRecipient, uint256 royaltyAmount) =
                _calculateRoyalties(pool, swapOutputAmount);

            if (royaltyAmount > 0) {
                swapOutputAmount -= royaltyAmount;

                token.safeTransfer(royaltyRecipient, royaltyAmount);
                emit DittoRouterRoyaltiesRoyaltyIssued(
                    msg.sender, address(pool), royaltyRecipient, swapOutputAmount, royaltyAmount
                );
            }

            token.safeTransfer(address(tokenRecipient), swapOutputAmount);

            outputAmount += swapOutputAmount;

            unchecked {
                ++i;
            }
        }

        // Aggregate slippage check
        if (outputAmount < minOutput) {
            revert DittoRoyaltyRouterOutputAmountTooLow();
        }
    }

    ///@inheritdoc DittoRouter
    function _robustSwapNftsForTokens(
        RobustNftInSwap[] calldata swapList,
        address tokenRecipient
    ) internal override returns (uint256 outputAmount) {
        // Try doing each swap
        uint256 numSwaps = swapList.length;
        outputAmount = 0;
        for (uint256 i; i < numSwaps;) {
            outputAmount += _robustSwapNftsForTokensIteration(swapList[i], tokenRecipient);
            unchecked {
                ++i;
            }
        }
    }

    ///@inheritdoc DittoRouter
    function _robustSwapNftsForTokensIteration(
        RobustNftInSwap calldata swap,
        address tokenRecipient
    ) internal override returns (uint256 outputAmount) {
        IDittoPool pool = swap.pool;
        CurveErrorCode cError;
        (cError, outputAmount) = _getSellQuoteThrowAwayUnneeded(pool, swap.nftIds.length, swap.swapData);
        if (cError != CurveErrorCode.OK) {
            return 0;
        }

        (address royaltyRecipient, uint256 royaltyAmount) = _calculateRoyalties(pool, outputAmount);

        // If at least equal to our minOutput, proceed
        if (outputAmount - royaltyAmount >= swap.minOutput) {
            if (royaltyAmount > 0) {
                // Do the swap and update outputAmount with how many tokens we got
                outputAmount = pool.swapNftsForTokens(
                    SwapNftsForTokensArgs({
                        nftIds: swap.nftIds,
                        lpIds: swap.lpIds,
                        minExpectedTokenOutput: 0,
                        nftSender: msg.sender,
                        tokenRecipient: payable(address(this)),
                        permitterData: swap.permitterData,
                        swapData: swap.swapData
                    })

                );

                outputAmount -= royaltyAmount;

                ERC20 token = ERC20(pool.token());
                if (royaltyAmount > 0) {
                    token.safeTransfer(royaltyRecipient, royaltyAmount);
                    emit DittoRouterRoyaltiesRoyaltyIssued(
                        msg.sender,
                        address(pool),
                        royaltyRecipient,
                        outputAmount + royaltyAmount,
                        royaltyAmount
                    );
                }
                token.safeTransfer(tokenRecipient, outputAmount);
            } else {
                // Do the swap and update outputAmount with how many tokens we got
                outputAmount = pool.swapNftsForTokens(SwapNftsForTokensArgs({
                    nftIds: swap.nftIds,
                    lpIds: swap.lpIds, 
                    minExpectedTokenOutput: 0, 
                    nftSender: msg.sender,
                    tokenRecipient: tokenRecipient,
                    permitterData: swap.permitterData,
                    swapData: swap.swapData
                }));
            }
        }
    }

    /**
     * @notice Royalty querying
     * Even though cost might be incremental between nft buys of a pool
     * the order of the buy doesn't matter, that's why we aggregate the
     * cost of each individual nft bought, and use FETCH_TOKEN_ID to query
     * the default royalty info, or a specific set for this router.
     * 
     * @param pool The pool to query
     * @param token The token to query
     * @param salePrice The sale price of the nft
     * @return royalties The amount of royalties to pay
     */
    function _calculateAndIssueTokenRoyalties(
        IDittoPool pool,
        ERC20 token,
        uint256 salePrice
    ) internal returns (uint256 royalties) {
        address recipient;

        (recipient, royalties) = _calculateRoyalties(pool, salePrice);

        if (royalties > 0) {
            // issue payment to royalty recipient
            token.safeTransferFrom(msg.sender, recipient, royalties);
            emit DittoRouterRoyaltiesRoyaltyIssued(msg.sender, address(pool), recipient, salePrice, royalties);
        }
    }

    function _calculateRoyalties(
        IDittoPool pool,
        uint256 salePrice
    ) internal view returns (address recipient, uint256 royalties) {
        (recipient, royalties) = calculateRoyalties(address(pool.nft()), salePrice);
        
        // validate royalty amount
        if (salePrice < royalties) {
            revert DittoRoyaltyRouterRoyaltyExceedsSalePrice();
        }
    }

    function _getRoyaltyStatus(address collection)
        internal
        view
        returns (address lookupAddress, bool collectionSupportsRoyalty)
    {
        // get royalty lookup address from the shared royalty registry
        lookupAddress = ROYALTY_REGISTRY.getRoyaltyLookupAddress(address(collection));
        collectionSupportsRoyalty =
            IERC2981(lookupAddress).supportsInterface(type(IERC2981).interfaceId);
    }
}
