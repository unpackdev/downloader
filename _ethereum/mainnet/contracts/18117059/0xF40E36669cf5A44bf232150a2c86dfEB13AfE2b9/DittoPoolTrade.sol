// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "./CurveErrorCode.sol";

import { EnumerableSet } from
    "../../lib/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import { EnumerableMap } from
    "../../lib/openzeppelin-contracts/contracts/utils/structs/EnumerableMap.sol";
import "./SafeTransferLib.sol";
import "./ERC20.sol";

import "./Fee.sol";
import "./SwapArgs.sol";
import "./NftCostData.sol";
import "./IDittoPool.sol";
import "./IDittoRouter.sol";
import "./DittoPoolMain.sol";


/**
 * @title DittoPool
 * @notice Parent contract defines common functions for DittoPool AMM shared liquidity trading pools.
 */
abstract contract DittoPoolTrade is DittoPoolMain {
    using SafeTransferLib for ERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToUintMap;

    // ***************************************************************
    // * ========================= EVENTS ========================== *
    // ***************************************************************

    event DittoPoolTradeSwappedTokensForNfts(
        address caller,
        SwapTokensForNftsArgs args,
        uint128 newBasePrice,
        uint128 newDelta
    );
    event DittoPoolTradeSwappedTokensForNft(
        uint256 sellerLpId,
        uint256 nftId,
        uint256 price,
        Fee fee
    );

    event DittoPoolTradeSwappedNftsForTokens(
        address caller,
        SwapNftsForTokensArgs args,
        uint128 newBasePrice,
        uint128 newDelta
    );
    event DittoPoolTradeSwappedNftForTokens(
        uint256 buyerLpId,
        uint256 nftId,
        uint256 price,
        Fee fee
    );

    // ***************************************************************
    // * ========================= ERRORS ========================== *
    // ***************************************************************

    error DittoPoolTradeBondingCurveError(CurveErrorCode error);
    error DittoPoolTradeNoNftsProvided();
    error DittoPoolTradeNftAndLpIdsMustBeSameLength();
    error DittoPoolTradeInvalidTokenRecipient();
    error DittoPoolTradeInsufficientBalanceToBuyNft();
    error DittoPoolTradeInsufficientBalanceToPayFees();
    error DittoPoolTradeInTooManyTokens();
    error DittoPoolTradeOutTooFewTokens();
    error DittoPoolTradeNftNotOwnedByPool(uint256 nftId);
    error DittoPoolTradeInvalidTokenSender();
    error DittoPoolTradeNftIdDoesNotMatchSwapData();
    error DittoPoolTradeNftAndCostDataLengthMismatch();

    // ***************************************************************
    // * =========== FUNCTIONS TO TRADE WITH THE POOL ============== *
    // ***************************************************************

    ///@inheritdoc IDittoPool
    function swapTokensForNfts(
        SwapTokensForNftsArgs calldata args_
    ) external nonReentrant returns (uint256 inputAmount) {
        uint256 countNfts = args_.nftIds.length;

        // STEP 1: Input validation
        if (countNfts == 0) {
            revert DittoPoolTradeNoNftsProvided();
        }

        // STEP 2: Get price information from bonding curve
        NftCostData[] memory nftCostData;
        uint128 newBasePrice;
        uint128 newDelta;
        (inputAmount, nftCostData, newBasePrice, newDelta) =
            _calculateBuyInfoAndUpdatePoolParams(countNfts, args_.swapData, args_.maxExpectedTokenInput);
        
        _checkNftIdsMatch(args_.nftIds, nftCostData);
        
        // STEP 3: Take in tokens for sellers (doesn't include fees)
        if (_dittoPoolFactory.isWhitelistedRouter(msg.sender)) {
            IDittoRouter(msg.sender).poolTransferErc20From(
                _token, args_.tokenSender, address(this), inputAmount
            );
        } else {
            if (args_.tokenSender != msg.sender){
                revert DittoPoolTradeInvalidTokenSender();
            }
            _token.transferFrom(args_.tokenSender, address(this), inputAmount);
        }

        // STEP 4: Transfer nfts to buyer and adjust nft balance of seller accounts
        uint256[] memory sellersLpIds = _sendNftsToBuyer(args_.nftRecipient, args_.nftIds);

        // STEP 5: Increase the token balance of the positions selling the nfts
        _increaseTokenBalanceOfSellers(nftCostData, sellersLpIds, args_.nftIds);

        // STEP 6: Pay protocol and admin fees
        _payProtocolAndAdminFees(nftCostData);

        emit DittoPoolTradeSwappedTokensForNfts(msg.sender, args_, newBasePrice, newDelta);
    }

    ///@inheritdoc IDittoPool
    function swapNftsForTokens(
        SwapNftsForTokensArgs calldata args_
    ) external nonReentrant returns (uint256 outputAmount) {
        uint256 countNfts = args_.nftIds.length;
        bool isWhitelistedRouter = _dittoPoolFactory.isWhitelistedRouter(msg.sender);

        // STEP 1: Input validation
        if (countNfts == 0) {
            revert DittoPoolTradeNoNftsProvided();
        }
        if (countNfts != args_.lpIds.length) {
            revert DittoPoolTradeNftAndLpIdsMustBeSameLength();
        }
        if (args_.tokenRecipient == address(0)) {
            revert DittoPoolTradeInvalidTokenRecipient();
        }
        if(!isWhitelistedRouter && args_.nftSender != msg.sender){
            revert DittoPoolTradeInvalidTokenSender();
        }

        _checkPermittedTokens(args_.nftIds, args_.permitterData);

        // STEP 2: Get price information from bonding curve
        NftCostData[] memory nftCostData;
        uint128 newBasePrice;
        uint128 newDelta;
        (outputAmount, nftCostData, newBasePrice, newDelta) =
            _calculateSellInfoAndUpdatePoolParams(countNfts, args_.swapData, args_.minExpectedTokenOutput);

        _checkNftIdsMatch(args_.nftIds, nftCostData);

        // STEP 3: Charge the buyers for the Nfts by reducing their token balance
        _decreaseTokenBalanceOfBuyers(nftCostData, args_.nftIds, args_.lpIds);

        // STEP 4: Transfer Nfts from seller to buyer accounts
        _takeSpecificNftsFromSeller(isWhitelistedRouter, args_.nftSender, args_.nftIds, args_.lpIds);

        // STEP 5: Transfer the token proceeds to the seller and pay fees
        _token.safeTransfer(args_.tokenRecipient, outputAmount);

        // STEP 6: Pay protocol and admin fees
        _payProtocolAndAdminFees(nftCostData);

        emit DittoPoolTradeSwappedNftsForTokens(msg.sender, args_, newBasePrice, newDelta);
    }

    ///@inheritdoc IDittoPool
    function getBuyNftQuote(uint256 numNfts_, bytes calldata swapData_)
        external
        view
        virtual
        returns (
            CurveErrorCode error,
            uint256 newBasePrice,
            uint256 newDelta,
            uint256 inputAmount,
            NftCostData[] memory nftCostData
        );

    ///@inheritdoc IDittoPool
    function getSellNftQuote(uint256 numNfts_, bytes calldata swapData_)
        external
        view
        virtual
        returns (
            CurveErrorCode error,
            uint256 newBasePrice,
            uint256 newDelta,
            uint256 outputAmount,
            NftCostData[] memory nftCostData
        );

    // ***************************************************************
    // * ============= INTERNAL HELPER FUNCTIONS =================== *
    // ***************************************************************
    /**
     * Check that the cost data matches the nft ids if that is important for the curve type 
     *   giving the cost data
     * @param nftIds_ The nft ids
     * @param nftCostData_ The cost data that may or may not require specific nft ids
     */
    function _checkNftIdsMatch(
        uint256[] memory nftIds_, 
        NftCostData[] memory nftCostData_
    ) internal pure {
        uint256 countNfts = nftIds_.length;
        if (countNfts != nftCostData_.length) {
            revert DittoPoolTradeNftAndCostDataLengthMismatch();
        }
        for (uint256 i = 0; i < countNfts;) {
            if (nftCostData_[i].specificNftId && nftIds_[i] != nftCostData_[i].nftId) {
                revert DittoPoolTradeNftIdDoesNotMatchSwapData();
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * Pays protocol and admin fees to the appropriate recipients
     * 
     * @param nftCostData_ the cost data including the fees
     */
    function _payProtocolAndAdminFees(NftCostData[] memory nftCostData_) internal {
        uint256 totalProtocolFee;
        uint256 totalAdminFee;
        uint256 numItems = nftCostData_.length;

        for (uint256 i = 0; i < numItems;) {
            totalProtocolFee += nftCostData_[i].fee.protocol;
            totalAdminFee += nftCostData_[i].fee.admin;
            unchecked {
                ++i;
            }
        }


        ERC20 token = _token;
        uint256 balance = token.balanceOf(address(this));
        if (balance < totalProtocolFee + totalAdminFee) {
            revert DittoPoolTradeInsufficientBalanceToPayFees();
        }
        token.safeTransfer(_dittoPoolFactory.protocolFeeRecipient(), totalProtocolFee);
        token.safeTransfer(_adminFeeRecipient, totalAdminFee);
    }

    /**
     * @notice In purchases of NFTs leaving the pool, increase token balance accounting of the NFT seller in the pool.
     * @param nftCostData array of NFT buy cost data
     * @param sellersLpIds_ list of addresses of NFT selling counterparties (LP providers within the pool) in this trade
     */
    function _increaseTokenBalanceOfSellers(
        NftCostData[] memory nftCostData,
        uint256[] memory sellersLpIds_,
        uint256[] memory nftIds_
    ) private {
        uint256 sellerLpId;
        uint256 sellerCurrentBalance;
        uint256 countSellerPositions = sellersLpIds_.length;

        for (uint256 i = 0; i < countSellerPositions;) {
            sellerLpId = sellersLpIds_[i];
            (, sellerCurrentBalance) = _lpIdToTokenBalance.tryGet(sellerLpId);
            _lpIdToTokenBalance.set(
                sellerLpId, 
                sellerCurrentBalance + nftCostData[i].price + nftCostData[i].fee.lp
            );

            emit DittoPoolTradeSwappedTokensForNft(
                sellerLpId,
                nftIds_[i],
                nftCostData[i].price,
                nftCostData[i].fee
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice In sales of NFTs into the pool for tokens, decrease the NFT seller's tokens balance accounting in the pool.
     * @dev this function throws if the liquidity provider does not have enough tokens to buy the NFTs
     * @param nftCostData_ array of NFT sell cost data
     * @param buyerLpIds_ the NFT buying counterparties, LP providers within the pool's Lp Position Token Ids
     */
    function _decreaseTokenBalanceOfBuyers(
        NftCostData[] memory nftCostData_,
        uint256[] memory nftIds_,
        uint256[] memory buyerLpIds_
    ) private {
        uint256 buyerLpId;
        uint256 buyerCurrentBalance;
        uint256 countBuyerPositions = buyerLpIds_.length;
        uint256 sellPriceIgnoreLpFee;
        for (uint256 i = 0; i < countBuyerPositions;) {
            buyerLpId = buyerLpIds_[i];
            sellPriceIgnoreLpFee = nftCostData_[i].price - nftCostData_[i].fee.lp;
            buyerCurrentBalance = _lpIdToTokenBalance.get(buyerLpId);
            if (buyerCurrentBalance < sellPriceIgnoreLpFee) {
                revert DittoPoolTradeInsufficientBalanceToBuyNft();
            }

            emit DittoPoolTradeSwappedNftForTokens(
                buyerLpId,
                nftIds_[i],
                nftCostData_[i].price,
                nftCostData_[i].fee
            );

            unchecked {
                _lpIdToTokenBalance.set(buyerLpId, buyerCurrentBalance - sellPriceIgnoreLpFee);
                ++i;
            }
        }
    }

    /**
     * @notice Updates LP position NFT metadata on trades, as LP's LP information changes due to the trade
     * @dev see [EIP-4906](https://eips.ethereum.org/EIPS/eip-4906) EIP-721 Metadata Update Extension
     * @param lpId_ LP position NFT token id whose metadata needs updating
     */
    function _updateLpNftMetadataOnTrade(uint256 lpId_) internal {
        _lpNft.emitMetadataUpdate(lpId_);
    }

    /**
     * @notice In a purchase of NFTs leaving the pool (`swapTokenForNfts`), sends NFTs to buyer, and
     * updates the pool's internal accounting of NFTs in the pool
     * @param nftRecipient_ the address to send the NFTs to
     * @param nftIds_ the list of specific NFT token Ids being purchased out of the pool in this transaction
     * @return sellersLpIds position ids of the lp positions selling within the pool
     */
    function _sendNftsToBuyer(
        address nftRecipient_,
        uint256[] calldata nftIds_
    ) internal returns (uint256[] memory sellersLpIds) {
        uint256 countNftIds = nftIds_.length;

        uint256 nftId;
        sellersLpIds = new uint256[](countNftIds);

        for (uint256 i = 0; i < countNftIds;) {
            nftId = nftIds_[i];

            if (_poolOwnedNftIds.contains(nftId) == false) {
                revert DittoPoolTradeNftNotOwnedByPool(nftId);
            }

            _nft.safeTransferFrom(address(this), nftRecipient_, nftId);

            _poolOwnedNftIds.remove(nftId);
            uint256 prevOwnerLpId = _nftIdToLpId[nftId];
            delete _nftIdToLpId[nftId];
            _lpIdToNftBalance[prevOwnerLpId]--;

            _updateLpNftMetadataOnTrade(prevOwnerLpId);
            sellersLpIds[i] = prevOwnerLpId;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice In a sale of NFTs into the pool, transfers the NFTs from the seller to the pool, and
     * updates the pool's internal accounting of NFTs in the pool
     * @dev Sends NFTs to recipients
     * @dev This adds the ids to to the global id set and increments the nft count for each buyer.
     * @param from_ the address to take the NFTs from, only used if msg.sender is an approved IDittoRouter
     * @param nftIds_ the list of specific NFT token Ids being purchased into the pool in this transaction
     * @param buyerLpIds_ the list of addresses of NFT buying counterparties (LP providers within the pool) buying NFTs in this trade
     */
    function _takeSpecificNftsFromSeller(
        bool isWhitelistedRouter_,
        address from_,
        uint256[] calldata nftIds_,
        uint256[] memory buyerLpIds_
    ) internal {
        uint256 countNftIds = nftIds_.length;
        uint256 nftId;
        for (uint256 i = 0; i < countNftIds;) {
            nftId = nftIds_[i];
            if (isWhitelistedRouter_) {
                IDittoRouter(msg.sender).poolTransferNftFrom(_nft, from_, address(this), nftId);
            } else {
                _nft.transferFrom(msg.sender, address(this), nftId);
            }
            _poolOwnedNftIds.add(nftId);
            _nftIdToLpId[nftId] = buyerLpIds_[i];
            _lpIdToNftBalance[buyerLpIds_[i]]++;

            _updateLpNftMetadataOnTrade(buyerLpIds_[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice In purchase of NFTs out of the pool, call bonding curve to find out how much erc20 is required, and
     * update new prices for the next NFT in the pool after this trade completes
     * @param numNFTs_ the number of NFTs being purchased
     * @param swapData_ extra data to be passed to the curve
     * @param maxExpectedTokenInput_ the maximum amount of tokens the user is willing to pay for the NFTs
     * @return inputAmount the amount of tokens the user needs to send to pay for the NFTsgetProtocolFee
     * @return nftCostData the data returned from the bonding curve
     */
    function _calculateBuyInfoAndUpdatePoolParams(
        uint256 numNFTs_,
        bytes calldata swapData_,
        uint256 maxExpectedTokenInput_
    ) internal returns (
        uint256 inputAmount, 
        NftCostData[] memory nftCostData,
        uint128 newBasePrice,
        uint128 newDelta
    ) {
        CurveErrorCode error;
        // Save on 2 SLOADs by caching
        uint128 currentBasePrice = _basePrice;
        uint128 currentDelta = _delta;
        (error, newBasePrice, newDelta, inputAmount, nftCostData) = _getBuyInfo(
            currentBasePrice,
            currentDelta,
            numNFTs_,
            swapData_,
            Fee({lp: _feeLp, admin: _feeAdmin, protocol: _dittoPoolFactory.getProtocolFee()})
        );

        // Revert if bonding curve had an error
        if (error != CurveErrorCode.OK) {
            revert DittoPoolTradeBondingCurveError(error);
        }

        // Revert if input is more than expected
        if (inputAmount > maxExpectedTokenInput_) {
            revert DittoPoolTradeInTooManyTokens();
        }

        if (currentBasePrice != newBasePrice) {
            _changeBasePrice(newBasePrice);
        }

        if (currentDelta != newDelta) {
            _changeDelta(newDelta);
        }
    }

    /**
     * @notice In sales of NFTs into the pool, call bonding curve to find out
     *   how much money the seller will receive, and update new prices for the
     *   next NFT in the pool after this trade completes
     * @param numNFTs_ the number of NFTs being purchased
     * @param swapData_ extra data to be passed to the curve
     * @param minExpectedTokenOutput_ minimium amount of ERC20 msg.sender is willing
     *   to recieve for the sale of their NFTs
     * @return outputAmount the amount of tokens the msg.sender will recieve
     *   from the sale of their NFTs into the pool
     * @return nftCostData the data returned from the bonding curve
     */
    function _calculateSellInfoAndUpdatePoolParams(
        uint256 numNFTs_,
        bytes calldata swapData_,
        uint256 minExpectedTokenOutput_
    ) internal returns (
        uint256 outputAmount, 
        NftCostData[] memory nftCostData,
        uint128 newBasePrice,
        uint128 newDelta
    ) {
        // Save on 2 SLOADs by caching
        uint128 currentBasePrice = _basePrice;
        uint128 currentDelta = _delta;

        CurveErrorCode error;
        (error, newBasePrice, newDelta, outputAmount, nftCostData) =
            _getSellInfo(
                currentBasePrice,
                currentDelta,
                numNFTs_,
                swapData_,
                Fee({lp: _feeLp, admin: _feeAdmin, protocol: _dittoPoolFactory.getProtocolFee()})
            );

        // Revert if bonding curve had an error
        if (error != CurveErrorCode.OK) {
            revert DittoPoolTradeBondingCurveError(error);
        }

        // Revert if output is too little
        if (outputAmount < minExpectedTokenOutput_) {
            revert DittoPoolTradeOutTooFewTokens();
        }

        if (currentBasePrice != newBasePrice) {
            _changeBasePrice(newBasePrice);
        }

        if (currentDelta != newDelta) {
            _changeDelta(newDelta);
        }
    }

    /**
     * @notice Calculate the total fees and price per NFT for a uniform trade, meaning all nfts 
     *   involved in the trade have the same price
     * 
     * @param totalCost_ The total cost across all nfts in the trade
     * @param numItems_ The number of nfts in the trade. Assumed not to be zero
     * @param feeRates_ The fees to be applied to the trade
     * @return totalFees_ The total fees to be paid for the trade
     * @return nftCostData_ The price and fees per nft in the trade
     */
    function _calculateUniformNftCostData(
        uint256 totalCost_,
        uint256 numItems_,
        Fee memory feeRates_
    ) internal pure returns (
        uint256 totalFees_,
        NftCostData[] memory nftCostData_
    ) {
        uint256 pricePerNft = totalCost_ / numItems_;

        Fee memory calculatedFees = Fee({
            protocol: _mul(totalCost_, feeRates_.protocol),
            admin: _mul(totalCost_, feeRates_.admin),
            lp: _mul(totalCost_, feeRates_.lp)
        });

        totalFees_ = calculatedFees.protocol + calculatedFees.admin + calculatedFees.lp;

        Fee memory calculatedFeesPerNft = Fee({
            protocol: calculatedFees.protocol / numItems_,
            admin: calculatedFees.admin / numItems_,
            lp: calculatedFees.lp / numItems_
        });

        nftCostData_ = new NftCostData[](numItems_);

        for (uint256 i = 0; i < numItems_;) {
            nftCostData_[i].price = pricePerNft;
            nftCostData_[i].fee = calculatedFeesPerNft;

            unchecked {
                ++i;
            }
        }
    }

    // ***********************************************************************
    // * ============= INTERNAL HELPER FUNCTIONS (Curve) =================== *
    // ***********************************************************************

    /**
     * @notice Given the current state of the pair and the trade, computes how much the user
     * should pay to purchase an NFT from the pair, the new base price, and other values.
     * @param basePrice_ The current selling base price of the pair, in tokens
     * @param delta_ The delta parameter of the pair, what it means depends on the curve
     * @param numItems_ The number of NFTs the user is buying from the pair
     * @param fee_ The fee Lp, Admin, and Protocol fee multipliers
     * @return error Any math calculation errors, only Error.OK means the returned values are valid
     * @return newBasePrice The updated selling base price, in tokens
     * @return newDelta The updated delta, used to parameterize the bonding curve
     * @return inputValue The amount that the user should pay, in tokens
     * @return nftCostData The fees and buyPriceAndLpFeePerNft for each NFT being purchased
     */
    function _getBuyInfo(
        uint128 basePrice_,
        uint128 delta_,
        uint256 numItems_,
        bytes calldata swapData_,
        Fee memory fee_
    )
        internal
        virtual
        returns (
            CurveErrorCode error,
            uint128 newBasePrice,
            uint128 newDelta,
            uint256 inputValue,
            NftCostData[] memory nftCostData
        );

    /**
     * @notice Given the current state of the pair and the trade, computes how much the user
     * should receive when selling NFTs to the pair, the new base price, and other values.
     * @param basePrice_ The current selling base price of the pair, in tokens
     * @param delta_ The delta parameter of the pair, what it means depends on the curve
     * @param numItems_ The number of NFTs the user is selling to the pair
     * @param fee_ The Lp, Admin, and Protocol fees multipliers
     * @return error Any math calculation errors, only Error.OK means the returned values are valid
     * @return newBasePrice The updated selling base price, in tokens
     * @return newDelta The updated delta, used to parameterize the bonding curve
     * @return outputValue The amount that the user should receive, in tokens
     * @return nftCostData The fees and sellPricePerNftWithoutFees for each NFT being sold
     */
    function _getSellInfo(
        uint128 basePrice_,
        uint128 delta_,
        uint256 numItems_,
        bytes calldata swapData_,
        Fee memory fee_
    )
        internal
        virtual
        returns (
            CurveErrorCode error,
            uint128 newBasePrice,
            uint128 newDelta,
            uint256 outputValue,
            NftCostData[] memory nftCostData
        );
}
