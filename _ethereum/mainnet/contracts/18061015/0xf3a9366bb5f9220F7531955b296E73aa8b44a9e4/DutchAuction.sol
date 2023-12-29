// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./IERC721.sol";
import "./IERC1155.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./AdminControl.sol";
import "./Address.sol";
import "./IERC721CreatorCore.sol";
import "./IERC1155CreatorCore.sol";
import "./IRoyaltyEngine.sol";
import "./EnumerableSet.sol";
import "./IDutchAuction.sol";

/**
 * @title DutchAuction
 * @dev This contract enables collectors and curators to run their own auctions.It is a unique type of auction
 * where the price of an item starts high and gradually decreases until it reachs the reserved price
 *
 */
contract DutchAuction is ReentrancyGuard, AdminControl {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice details of the buyer
    /// @param price the price of the NFTs
    /// @param quantity the nft quantity purchased at actual price
    /// @param tax the tax rate
    /// @param priceDiscount the discount price of the nfts
    /// @param quantityDiscount the nft quantity purchased at the discount price
    /// @param taxDiscount the tax for discount price
    /// @param totalCap the total nfts brought by the buyer
    /// @param rebateClaimed represents that rebate is claimed or not
    struct BuyerDetails {
        uint256[] price;
        uint256[] quantity;
        uint256[] tax;
        uint256[] priceDiscount;
        uint256[] quantityDiscount;
        uint256[] taxDiscount;
        uint256 totalCap;
        bool rebateClaimed;
    }

    /// @notice LatestSaleDetails of the particular auction id
    /// @param finalPrice the price of the latest buy
    /// @param nextTokenId the id of the next token to buy
    /// @param currentSupply the total number of tokens purchased by all buyers
    /// @param fullDiscountSupply the total number of tokens purchased with full discount
    /// @param zeroDiscountSupply the total number of tokens purchased with zero discount
    /// @param auctionEnded represents that auction is ended or not
    /// @param isReachedMaxId represents that minting reacheed the maxId 
    struct LatestSaleDetails {
        uint256 finalPrice;
        uint256 nextTokenId;
        uint256 currentSupply;
        uint256 fullDiscountSupply;
        uint256 zeroDiscountSupply;
        bool auctionEnded;
        bool isReachedMaxId;
    }

    /// @notice emits an event when the auction is created or updated.
    /// @param auctionId contains the id of the created sale
    /// @param list contains the details of auction created
    /// @param createdOrUpdated the details provide whether auction is created or updated
    event AuctionCreatedorUpdated(
        string auctionId,
        IDutchAuction.DutchAuctionList list,
        string createdOrUpdated
    );

    /// @notice emits an event when the NFT is purchased.
    /// @param auctionId the id of the created auction
    /// @param quantity the number of tokens purchased
    /// @param unit1155 the uints if ERC1155
    /// @param currentPrice the current price of the single token
    /// @param price the price amount of the purchase
    /// @param tax the tax amount of the purchase
    /// @param nonce the nonce used for the signature
    /// @param buyer the buyer address
    /// @param tokenIds the token ids brought by the buyer
    event BuyExecuted(
        string auctionId,
        uint256 quantity,
        uint256 unit1155,
        uint256 currentPrice,
        uint256 price,
        uint256 tax,
        string nonce,
        address buyer,
        uint256[] tokenIds
    );

    /// @notice emits an event when auction is ended
    /// @param auctionId the id of the created auction
    /// @param soldQuantity the total number of tokens sold
    /// @param finalPrice the final price of the NFT
    /// @param tokenIds the token ids brought by the buyer
    event AuctionEnded(
        string auctionId,
        uint256 soldQuantity,
        uint256 finalPrice,
        uint256[] tokenIds
    );

    /// @notice emits an event when the rebate is claimed
    /// @param auctionId the id of the created sale
    /// @param buyer the buyer address where the rebate is paid
    /// @param rebateAmount the rebate amount paid to the buyer
    /// @param rebateTax the rebate tax paid to the buyer
    /// @param paymentCurrency the currency the rebate is paid at
    event Rebated(
        string auctionId,
        address buyer,
        uint256 rebateAmount,
        uint256 rebateTax,
        address paymentCurrency
    );

    /// @notice emits an event when the auction is cancelled
    /// @param auctionId contains the id of the created auction
    event CancelAuction(string auctionId);

    /// @notice emits an event when an royalty payout is executed
    /// @param tokenContract the NFT contract address
    /// @param recipient the address of the royalty recipient(s)
    /// @param shares the shares sent to the royalty recipient(s)
    event RoyaltyPayout(
        address tokenContract,
        address recipient,
        uint256 shares
    );

    /// @notice emits an event when EndTime is updated
    /// @param auctionId contains the id of the created auction
    /// @param endTimeNew The new EndTime
    event EndTimeUpdated(string auctionId, uint256 endTimeNew);

    /// @notice emits an event when Reserved Price is updated
    /// @param auctionId contains the id of the created auction
    /// @param reservePriceNew The new reserved price address
    event ReservePriceUpdated(string auctionId, uint256 reservePriceNew);

    /// @notice emits an event when an utility And royalty address are updated.
    /// @param dutchUtilityNew The new DutchUtility address
    /// @param royaltySupporNew The new royaltySupport address
    event UpdatedUtilityAndRoyaltyAddress(
        address dutchUtilityNew,
        address royaltySupporNew
    );

    // The address of the RoyaltyEngine to use via this contract
    IRoyaltyEngine public royaltySupport;

    // The address of the DutchUtility to use via this contract
    IDutchAuction public dutchUtility;

    // interface ID constants
    bytes4 private constant ERC721_INTERFACE_ID = 0x80ac58cd;
    bytes4 private constant ERC1155_INTERFACE_ID = 0xd9b67a26;

    // to validate auction Id
    mapping(string => bool) public usedAuctionId;

    // to list the auction details with respect to the auction id
    mapping(string => IDutchAuction.DutchAuctionList) private listings;

    // to set the buyers address with respect to the auction id
    mapping(string => EnumerableSet.AddressSet) private buyerAddress;

    // to set the sale details with respect to the auction id
    mapping(string => LatestSaleDetails) private latestSaleInfo;

    // to set the  buyerInfo with respect to the auction id and buyer
    mapping(string => mapping(address => BuyerDetails)) private buyerInfo;

    // to validate discount signature
    mapping(bytes => bool) public discountUsed;

    constructor(IRoyaltyEngine _royaltySupport, address dutchUtilityArg) {
        require(dutchUtilityArg != address(0), "invalid dutchUtilityArg");
        royaltySupport = _royaltySupport;
        dutchUtility = IDutchAuction(dutchUtilityArg);
    }

    /**
     * @notice createOrUpdateDutchAuction, creates and updates an auction
     * @param list the listing details to create an auction
     * @param dutchAuctionID the id of the auction
     */
    function createOrUpdateDutchAuction(
        string memory dutchAuctionID,
        IDutchAuction.DutchAuctionList memory list
    ) external nonReentrant {
        // checks caller: to be only called by the tokenOwner or admin
        require(
            isAdmin(msg.sender) || list.collectionList.tokenOwner == msg.sender,
            "allowed: only admin or token owner"
        );

        //calls the error handelling functionalities on utility contract
        dutchUtility.__beforeCreateAuction(list);

        // calls if the auction is created or updated
        if (!usedAuctionId[dutchAuctionID]) {
            listings[dutchAuctionID] = list;

            usedAuctionId[dutchAuctionID] = true;

            emit AuctionCreatedorUpdated(dutchAuctionID, list, "listed");
        } else if (usedAuctionId[dutchAuctionID]) {
            require(list.auctionStartTime > block.timestamp, "sale started");
            listings[dutchAuctionID] = list;
            emit AuctionCreatedorUpdated(dutchAuctionID, list, "updated");
        }
    }

    /**
     * @notice buy, buying the token(s) at current dutch auction price
     * @param dutchAuctionID the id of the created auction
     * @param price the buy amount to purchase NFT(s)
     * @param tax the tax amount of the purchase
     * @param quantity the number of tokens to be purchased
     * @param unit1155 the quantity for 1155
     * @param blacklistedProof the merkle tree path of buyer address
     * @param discount the discount related information
     */
    function buy(
        string memory dutchAuctionID,
        uint256 price,
        uint256 tax,
        uint256 quantity,
        uint256 unit1155,
        bytes32[] memory blacklistedProof,
        IDutchAuction.Discount memory discount
    ) external payable nonReentrant {
        // checks for auctionId is created for auction
        require(usedAuctionId[dutchAuctionID], "unsupported auction");

        IDutchAuction.NftContractList memory nftData = listings[dutchAuctionID]
            .collectionList;

        // checks whether is paying the amount with required amount
        if (listings[dutchAuctionID].paymentCurrency == address(0)) {
            require(msg.value == price + tax, "insufficient ETH");
        }

        uint256 refundTax; // refund Tax
        uint256 tempAmount; // refund Amount

        // validates the purchase data before buying the NFT
        (tempAmount, refundTax) = dutchUtility.__buyValidation(
            dutchAuctionID,
            msg.sender,
            IDutchAuction.BuyList(
                price,
                tax,
                quantity,
                unit1155,
                blacklistedProof,
                discount
            )
        );

        // transfers the excess amount to buyer
        if (
            listings[dutchAuctionID].paymentCurrency == address(0) &&
            (tempAmount + refundTax > 0)
        ) {
            (bool success, ) = payable(msg.sender).call{
                value: (tempAmount + refundTax)
            }(new bytes(0));
            require(success, "txn failed");
        }

        // updates the actual price and tax based the current price.
        price = price - tempAmount;
        tax = tax - refundTax;

        // adds buyer to the sale
        if (!buyerAddress[dutchAuctionID].contains(msg.sender)) {
            buyerAddress[dutchAuctionID].add(msg.sender);
        }

        // adds discount signature
        if (nftData.isSignerRequired) {
            discountUsed[discount.signature] = true;
        } else if (discount.discountPercentage > 0) {
            discountUsed[discount.signature] = true;
        }

        uint256 buyQuantity = (
            nftData.saleType ==
                IDutchAuction.TypeOfSale.single_tokens_multiple_Quantity
                ? unit1155
                : quantity
        );

        // adds the buy details based on discount %
        if (
            nftData.isDiscountRequired && discount.discountPercentage == 10000
        ) {
            latestSaleInfo[dutchAuctionID].fullDiscountSupply += buyQuantity;
        } else if (
            nftData.isDiscountRequired && discount.discountPercentage > 0
        ) {
            buyerInfo[dutchAuctionID][msg.sender].priceDiscount.push(price);
            buyerInfo[dutchAuctionID][msg.sender].taxDiscount.push(tax);
            buyerInfo[dutchAuctionID][msg.sender].quantityDiscount.push(
                buyQuantity
            );
        } else if (
            discount.discountPercentage == 0 || !nftData.isDiscountRequired
        ) {
            latestSaleInfo[dutchAuctionID].zeroDiscountSupply += buyQuantity;
            buyerInfo[dutchAuctionID][msg.sender].price.push(price);
            buyerInfo[dutchAuctionID][msg.sender].tax.push(tax);
            buyerInfo[dutchAuctionID][msg.sender].quantity.push(buyQuantity);
        }    

        // updating the purchase quantity and currentPrice
        buyerInfo[dutchAuctionID][msg.sender].totalCap += buyQuantity;
        latestSaleInfo[dutchAuctionID].currentSupply += buyQuantity;

        // Current Price is Stored in TempAmount Variable.
        tempAmount = dutchUtility.getCurrentDutchPrice(dutchAuctionID);
        latestSaleInfo[dutchAuctionID].finalPrice = tempAmount;

        if (latestSaleInfo[dutchAuctionID].nextTokenId == 0) {
            latestSaleInfo[dutchAuctionID].nextTokenId = nftData.startTokenId;
        }

        // Payment Transfer
        if (listings[dutchAuctionID].paymentCurrency != address(0)) {
            if (nftData.isRebate) {
                IERC20(listings[dutchAuctionID].paymentCurrency)
                    .safeTransferFrom(msg.sender, address(this), price + tax);
            }
        }
        if (!nftData.isRebate) {
            paymentTransaction(
                dutchAuctionID,
                price,
                tax,
                listings[dutchAuctionID].paymentCurrency,
                msg.sender,
                false
            );
        }
        uint256[] memory tokenIds;

        // transfer or mint the NFT
        if (nftData.isInstantDeliver) {
            (
                tokenIds,
                latestSaleInfo[dutchAuctionID].nextTokenId
            ) = __tokenTransaction(
                dutchAuctionID,
                msg.sender,
                quantity,
                nftData.saleType ==
                    IDutchAuction.TypeOfSale.single_tokens_multiple_Quantity
                    ? unit1155
                    : nftData.unit1155
            );
        }

        emit BuyExecuted(
            dutchAuctionID,
            quantity,
            unit1155,
            tempAmount,
            price,
            tax,
            discount.nonce,
            msg.sender,
            tokenIds
        );
    }

    /**
     * @notice endAuction, ending the auction
     * @param dutchAuctionID the id of the created auction
     */
    function endAuction(
        string memory dutchAuctionID,
        bool isPriceAsReserve
    ) external nonReentrant {
        // checks for auctionId is created for auction
        require(usedAuctionId[dutchAuctionID], "unsupported auction");

        IDutchAuction.NftContractList memory nftData = listings[dutchAuctionID]
            .collectionList;
        // calculates the total price of the auction
        uint256 totalPrice = 0;
        // calculates the tax of the total auction
        uint256 totalTax = 0;

        // checks the caller to be only the token owner or admin
        require(
            isAdmin(msg.sender) || nftData.tokenOwner == msg.sender,
            "allowed: only admin or token owner"
        );
        // checks the auction is crossed the end time or all nft are sold out or reached the max id
        require(
            listings[dutchAuctionID].auctionEndTime <= block.timestamp ||
                latestSaleInfo[dutchAuctionID].currentSupply ==
                (
                    nftData.saleType ==
                        IDutchAuction.TypeOfSale.single_tokens_multiple_Quantity
                        ? nftData.unit1155
                        : nftData.noOfTokens
                ) ||
                latestSaleInfo[dutchAuctionID].isReachedMaxId,
            "can't end"
        );
        // checks whether the auction is already ended
        require(!latestSaleInfo[dutchAuctionID].auctionEnded, "already ended");
        // checks for any bid in the provided auction
        require(latestSaleInfo[dutchAuctionID].currentSupply > 0, "no bids");
        // Sets Reserve price as final price.
        if (isPriceAsReserve) {
            latestSaleInfo[dutchAuctionID].finalPrice = listings[dutchAuctionID]
                .reservedPrice;
        }

        // checks the contract has sufficient balance
        if (nftData.isRebate) {
            (totalPrice, totalTax) = dutchUtility.computeSettlementAmountAndTax(
                dutchAuctionID
            );

            // transferring the payment to the represented address
            paymentTransaction(
                dutchAuctionID,
                totalPrice,
                totalTax,
                listings[dutchAuctionID].paymentCurrency,
                msg.sender,
                true
            );
        }

        uint256[] memory tokenIds;
        uint256[] memory totalTokenIds = new uint256[](
            latestSaleInfo[dutchAuctionID].currentSupply
        );
        // transferring the nft to the represented buyers
        if (!nftData.isInstantDeliver) {
            uint256 count = 0;
            for (
                uint256 i = 0;
                i < buyerAddress[dutchAuctionID].length();
                i++
            ) {
                address buyerAdddress = buyerAddress[dutchAuctionID].at(i);
                uint256 totalCap = buyerInfo[dutchAuctionID][buyerAdddress]
                    .totalCap;
                uint256 tokenCount = nftData.saleType ==
                    IDutchAuction.TypeOfSale.single_tokens_multiple_Quantity
                    ? 1
                    : totalCap;
                uint256 quantity = nftData.saleType ==
                    IDutchAuction.TypeOfSale.single_tokens_multiple_Quantity
                    ? totalCap
                    : nftData.unit1155;

                (
                    tokenIds,
                    latestSaleInfo[dutchAuctionID].nextTokenId
                ) = __tokenTransaction(
                    dutchAuctionID,
                    buyerAdddress,
                    tokenCount,
                    quantity
                );

                for (uint256 j = 0; j < tokenIds.length; j++) {
                    totalTokenIds[count] = tokenIds[j];
                    count++;
                }
            }
        }

        emit AuctionEnded(
            dutchAuctionID,
            latestSaleInfo[dutchAuctionID].currentSupply,
            latestSaleInfo[dutchAuctionID].finalPrice,
            totalTokenIds
        );
        latestSaleInfo[dutchAuctionID].auctionEnded = true;
    }

    /**
     * @notice cancelAuction, cancels the auction
     * @param auctionId the auction id to cancel
     */
    function cancelAuction(string memory auctionId) external adminRequired {
        require(usedAuctionId[auctionId], "unsupported auction");
        require(!latestSaleInfo[auctionId].auctionEnded, "already ended");
        require(latestSaleInfo[auctionId].finalPrice == 0, "sale started");
        delete (listings[auctionId]);
        emit CancelAuction(auctionId);
    }

    /**
     * @notice rebate, transferring the excess amount to the buyer
     * @param dutchAuctionID the id of the created auction
     * @param buyer the buyer wallet address
     */
    function rebate(
        string memory dutchAuctionID,
        address buyer
    ) external nonReentrant {
        // checks for auctionId is created for auction
        require(usedAuctionId[dutchAuctionID], "unsupported auction");
        // Checks for buyer is a part of buyers list in the auction
        require(
            buyerAddress[dutchAuctionID].contains(buyer),
            "invalid address"
        );
        // checks whether the auction is ended or sold out all NFTs
        require(
            latestSaleInfo[dutchAuctionID].auctionEnded ||
                latestSaleInfo[dutchAuctionID].currentSupply ==
                (
                    listings[dutchAuctionID].collectionList.saleType ==
                        IDutchAuction.TypeOfSale.single_tokens_multiple_Quantity
                        ? listings[dutchAuctionID].collectionList.unit1155
                        : listings[dutchAuctionID].collectionList.noOfTokens
                ),
            "not ended"
        );
        // checks whether the rebate is already claimed
        require(
            !buyerInfo[dutchAuctionID][buyer].rebateClaimed,
            "already claimed"
        );

        uint256 rebateAmount;
        uint256 rebateTax;

        // gets the rebate amount and tax from claimable()
        (rebateAmount, rebateTax) = dutchUtility.claimable(
            dutchAuctionID,
            buyer
        );
        // checks the rebate amount is greater than zero
        require(rebateAmount > 0, "no claim");

        emit Rebated(
            dutchAuctionID,
            buyer,
            rebateAmount,
            rebateTax,
            listings[dutchAuctionID].paymentCurrency
        );

        buyerInfo[dutchAuctionID][buyer].rebateClaimed = true;

        // transfers the payment to the buyer address
        _handlePayment(
            msg.sender,
            payable(buyer),
            listings[dutchAuctionID].paymentCurrency,
            rebateAmount + rebateTax,
            true
        );
    }

    /**
     * @notice Settles the payment to all settlement addresses concerned.
     * @param _dutchAuctionID the id of the auction
     * @param _totalAmount the totalAmount to be paid by the seller
     * @param tax the tax to be paid
     * @param _paymentToken the address of payment Token
     * @param _from the from address
     * @param isRebate the transaction status for rebate or not
     */
    function paymentTransaction(
        string memory _dutchAuctionID,
        uint256 _totalAmount,
        uint256 tax,
        address _paymentToken,
        address _from,
        bool isRebate
    ) private {
        IDutchAuction.SettlementList memory settlement = listings[
            _dutchAuctionID
        ].payoutList;

        uint256 totalCommession;

        _handlePayment(
            _from,
            settlement.taxSettlementAddress,
            _paymentToken,
            tax,
            isRebate
        );

        // transfers the platformFee amount to the platformSettlementAddress
        if (
            settlement.platformSettlementAddress != address(0) &&
            settlement.platformFeePercentage > 0
        ) {
            _handlePayment(
                _from,
                settlement.platformSettlementAddress,
                _paymentToken,
                totalCommession += ((_totalAmount *
                    settlement.platformFeePercentage) / 10000),
                isRebate
            );
        }

        // transfers the commissionfee amount to the commissionAddress
        if (
            settlement.commissionAddress != address(0) &&
            settlement.commissionFeePercentage > 0
        ) {
            totalCommession += ((_totalAmount *
                settlement.commissionFeePercentage) / 10000);
            _handlePayment(
                _from,
                settlement.commissionAddress,
                _paymentToken,
                ((_totalAmount * settlement.commissionFeePercentage) / 10000),
                isRebate
            );
        }
        _totalAmount = _totalAmount - totalCommession;

        // royalty fee payout settlement
        if (royaltySupport != IRoyaltyEngine(address(0))) {
            (
                address payable[] memory recipients,
                uint256[] memory bps // Royalty amount denominated in basis points
            ) = royaltySupport.getCollectionRoyalty(
                    listings[_dutchAuctionID].collectionList.nftContractAddress
                );

            // payouts each royalty
            for (uint256 i = 0; i < recipients.length; ) {
                uint256 feeAmount;

                feeAmount = (bps[i] * _totalAmount) / 10000;

                // ensures that we aren't somehow paying out more than we have
                require(_totalAmount >= feeAmount, "insolvent");

                emit RoyaltyPayout(
                    listings[_dutchAuctionID].collectionList.nftContractAddress,
                    recipients[i],
                    feeAmount
                );

                _handlePayment(
                    msg.sender,
                    recipients[i],
                    _paymentToken,
                    feeAmount,
                    isRebate
                );
                unchecked {
                    _totalAmount -= feeAmount;
                    ++i;
                }
            }
        }

        // transfers the balance to the paymentSettlementAddress
        _handlePayment(
            _from,
            settlement.paymentSettlementAddress,
            _paymentToken,
            _totalAmount,
            isRebate
        );
    }

    /**
     * @notice Settles the payment based on the given parameters
     * @param _to the address to whom need to settle the payment
     * @param _paymentToken the address of the ERC20 Payment Token
     * @param _amount the amount to be transferred
     */
    function _handlePayment(
        address _from,
        address payable _to,
        address _paymentToken,
        uint256 _amount,
        bool isRebate
    ) private {
        bool success;
        if (_paymentToken == address(0)) {
            // transfers the native currency
            (success, ) = _to.call{value: _amount}(new bytes(0));
            require(success, "txn failed");
        } else {
            if (isRebate) {
                // transfers the ERC20 currency from contract
                IERC20(_paymentToken).safeTransfer(_to, _amount);
            } else if (!isRebate) {
                // transfers the ERC20 currency from buyer wallet
                IERC20(_paymentToken).safeTransferFrom(_from, _to, _amount);
            }
        }
    }

    /**
     * @notice Transfers the nfts for erc-721/1155 collection
     * @param dutchAuctionID the id of created auction
     * @param buyer the address of the nft to be minted or transferred
     * @param quantity the number of tokens to be minted or transferred
     * @param unit1155 the units of tokens if erc-1155 collection
     */
    function __tokenTransaction(
        string memory dutchAuctionID,
        address buyer,
        uint256 quantity,
        uint256 unit1155
    ) private returns (uint256[] memory buyTokenIds, uint256 tokenId) {
        buyTokenIds = new uint256[](quantity);
        tokenId = latestSaleInfo[dutchAuctionID].nextTokenId;
        IDutchAuction.NftContractList memory nftData = listings[dutchAuctionID]
            .collectionList;
        // transfers the token.
        if (!nftData.isMint) {
            for (uint256 i = 0; i < quantity; i++) {
                if (
                    IERC165(nftData.nftContractAddress).supportsInterface(
                        ERC721_INTERFACE_ID
                    )
                ) {
                    while (
                        IERC721(nftData.nftContractAddress).ownerOf(tokenId) !=
                        nftData.tokenOwner
                    ) {
                        require(
                            nftData.endTokenId >= tokenId,
                            "not enough token"
                        );
                        tokenId += 1;
                    }
                    // Transfers the ERC721 token(s)
                    IERC721(nftData.nftContractAddress).safeTransferFrom(
                        nftData.tokenOwner,
                        buyer,
                        tokenId
                    );
                    buyTokenIds[i] = tokenId;
                    tokenId += 1;
                } else if (
                    IERC165(nftData.nftContractAddress).supportsInterface(
                        ERC1155_INTERFACE_ID
                    )
                ) {
                    if (
                        nftData.saleType ==
                        IDutchAuction
                            .TypeOfSale
                            .multiple_tokens_with_Same_Quantity
                    ) {
                        while (
                            IERC1155(nftData.nftContractAddress).balanceOf(
                                nftData.tokenOwner,
                                tokenId
                            ) < unit1155
                        ) {
                            require(
                                nftData.endTokenId >= tokenId,
                                "not enough token"
                            );
                            tokenId += 1;
                        }

                        // Transfers the ERC1155 Token(s)
                        IERC1155(nftData.nftContractAddress).safeTransferFrom(
                            nftData.tokenOwner,
                            buyer,
                            tokenId,
                            unit1155,
                            "0x"
                        );
                        buyTokenIds[i] = tokenId;
                        tokenId += 1;
                    } else if (
                        nftData.saleType ==
                        IDutchAuction.TypeOfSale.single_tokens_multiple_Quantity
                    ) {
                        require(
                            IERC1155(nftData.nftContractAddress).balanceOf(
                                nftData.tokenOwner,
                                tokenId
                            ) > unit1155,
                            "insufficient quantity"
                        );
                        // transferring erc-1155
                        IERC1155(nftData.nftContractAddress).safeTransferFrom(
                            nftData.tokenOwner,
                            buyer,
                            tokenId,
                            unit1155,
                            "0x"
                        );
                        buyTokenIds[i] = tokenId;
                    }
                }
            }
            return (buyTokenIds, tokenId);
            // mints the NFT to buyer address
        } else if (nftData.isMint) {
            if (
                IERC165(nftData.nftContractAddress).supportsInterface(
                    ERC721_INTERFACE_ID
                )
            ) {
                // mints for erc-721 collection
                buyTokenIds = IERC721CreatorCore(nftData.nftContractAddress)
                    .mintExtensionBatch(buyer, uint16(quantity));
            } else if (
                IERC165(nftData.nftContractAddress).supportsInterface(
                    ERC1155_INTERFACE_ID
                )
            ) {
                address[] memory to = new address[](1);
                uint256[] memory amounts = new uint256[](quantity);
                string[] memory uris;
                to[0] = buyer;

                if (
                    nftData.saleType ==
                    IDutchAuction.TypeOfSale.multiple_tokens_with_Same_Quantity
                ) {
                    for (uint256 i = 0; i < quantity; i++) {
                        amounts[i] = unit1155;
                    }
                    // mints nft for erc-1155 collections for new nfts
                    buyTokenIds = IERC1155CreatorCore(
                        nftData.nftContractAddress
                    ).mintExtensionNew(to, amounts, uris);
                } else if (
                    nftData.saleType ==
                    IDutchAuction.TypeOfSale.single_tokens_multiple_Quantity
                ) {
                    amounts[0] = unit1155;
                    if (tokenId == 0) {
                        // mints nft for erc-1155 collections as new nfts
                        buyTokenIds = IERC1155CreatorCore(
                            nftData.nftContractAddress
                        ).mintExtensionNew(to, amounts, uris);
                        latestSaleInfo[dutchAuctionID]
                            .nextTokenId = buyTokenIds[0];
                    } else {
                        // mints nft for erc-1155 collections as existing nfts
                        buyTokenIds[0] = tokenId;
                        IERC1155CreatorCore(nftData.nftContractAddress)
                            .mintExtensionExisting(to, buyTokenIds, amounts);
                    }
                }
            }
            if (nftData.maxTokenIDRange != -1) {
                if (
                    buyTokenIds[buyTokenIds.length - 1] >=
                    uint256(nftData.maxTokenIDRange)
                ) {
                    latestSaleInfo[dutchAuctionID].isReachedMaxId = true;
                }
                require(
                    buyTokenIds[buyTokenIds.length - 1] <=
                        uint256(nftData.maxTokenIDRange),
                    "reached max id"
                );
            }

            return (buyTokenIds, buyTokenIds[buyTokenIds.length - 1]);
        }
    }

    /**
     * @notice Withdraw the funds to owner
     * @param paymentCurrency the address of the paymentCurrency
     */
    function withdraw(address paymentCurrency) external onlyOwner {
        bool success;
        if (paymentCurrency == address(0)) {
            (success, ) = payable(msg.sender).call{
                value: address(this).balance
            }(new bytes(0));
            require(success, "txn failed");
        } else if (paymentCurrency != address(0)) {
            // transfers the ERC20 currency
            IERC20(paymentCurrency).safeTransfer(
                payable(msg.sender),
                IERC20(paymentCurrency).balanceOf(address(this))
            );
        }
    }

    /**
     * @notice Updates the end time of auction
     * @param dutchAuctionID the id of created auction
     * @param endTime the end time to update
     */
    function updateEndTime(
        string memory dutchAuctionID,
        uint32 endTime
    ) external adminRequired {
        require(usedAuctionId[dutchAuctionID], "unsupported auction");
        // checks whether the auction is already ended
        require(!latestSaleInfo[dutchAuctionID].auctionEnded, "already ended");
        emit EndTimeUpdated(dutchAuctionID, endTime);
        listings[dutchAuctionID].auctionEndTime = endTime;
    }

    /**
     * @notice Updates the state variables in contract
     * @param dutchAuctionID the id of created Auction
     * @param reservedPrice the reserved price to update
     */
    function updateReservePrice(
        string memory dutchAuctionID,
        uint128 reservedPrice
    ) external adminRequired {
        require(usedAuctionId[dutchAuctionID], "unsupported auction");
        require(
            reservedPrice < dutchUtility.getCurrentDutchPrice(dutchAuctionID),
            "invalid arg"
        );
        emit ReservePriceUpdated(dutchAuctionID, reservedPrice);
        listings[dutchAuctionID].reservedPrice = reservedPrice;
    }

    /**
     * @notice Updates the state variables in contract
     * @param royaltySupportArg the address for royalty payment support
     * @param dutchUtilityArg the address for utility support
     */
    function updateUtilityAndRoyaltyAddress(
        address royaltySupportArg,
        address dutchUtilityArg
    ) external adminRequired {
        require(dutchUtilityArg != address(0), "Invalid dutchUtilityArg");
        emit UpdatedUtilityAndRoyaltyAddress(
            dutchUtilityArg,
            royaltySupportArg
        );
        royaltySupport = IRoyaltyEngine(royaltySupportArg);
        dutchUtility = IDutchAuction(dutchUtilityArg);
    }

    /**
     * @notice Gets the detils of the listed sale
     * @param dutchAuctionID the id of the created auction
     */
    function getListings(
        string memory dutchAuctionID
    ) external view returns (IDutchAuction.DutchAuctionList memory auctionist) {
        return listings[dutchAuctionID];
    }

    /**
     * @notice Gets the detils collection details of listed sale
     * @param dutchAuctionID the id of the created auction
     */
    function getLatestSaleInfo(
        string memory dutchAuctionID
    ) external view returns (LatestSaleDetails memory saleDetails) {
        return latestSaleInfo[dutchAuctionID];
    }

    /**
     * @notice Gets the buyers sale info of the listed sale
     * @param dutchAuctionID the id of the created auction
     * @param buyer the address of the buyer
     */
    function getBuyerInfo(
        string memory dutchAuctionID,
        address buyer
    ) external view returns (BuyerDetails memory buyerDetails) {
        return buyerInfo[dutchAuctionID][buyer];
    }

    /**
     * @notice Gets the list of all the buyers in the sale
     * @param dutchAuctionID the id of the created auction
     */
    function getBuyerAddress(
        string memory dutchAuctionID
    ) external view returns (address[] memory buyers) {
        return buyerAddress[dutchAuctionID].values();
    }
}
