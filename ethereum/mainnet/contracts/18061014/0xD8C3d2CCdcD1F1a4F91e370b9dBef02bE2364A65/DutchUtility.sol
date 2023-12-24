// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./IERC721.sol";
import "./IERC1155.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721CreatorCore.sol";
import "./IERC1155CreatorCore.sol";
import "./IDutchAuction.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./ECDSA.sol";

/**
 * @title ApprovalCheck, for getting the approval status
 */
interface ApprovalCheck {
    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);
}

/**
 * @title DutchUtility
 * @dev This is the peripheral contract, which supports the validation and computation parts
 * of the DutchAuction contract.
 */
contract DutchUtility is Ownable {
    using ECDSA for bytes32;

    // The address of the DutchAuction to use via this contract
    IDutchAuction public DutchAuction;

    // To ensure this contract initialized with DutchAuction Address
    bool initialized;

    constructor() {}

    /**
     * @notice initializes the DutchAuction
     * @param dutchAuction The address of the DutchAuction
     */
    function initializeDutchContract(address dutchAuction) external onlyOwner {
        require(Address.isContract(dutchAuction), "should be only contract");
        DutchAuction = IDutchAuction(dutchAuction);
        initialized = true;
    }

    /**
     * @notice Validates auction data before auction creation and updation
     * @param auctionList the list of the auction data
     */
    function __beforeCreateAuction(
        IDutchAuction.DutchAuctionList memory auctionList
    ) external view {
        IDutchAuction.DutchAuctionList memory list = auctionList;
        IDutchAuction.NftContractList memory nftData = list.collectionList;

        require(initialized, "need to initialize the dutch auction");
        // checks to provide only supported interface for nftContractAddress
        require(
            IERC165(nftData.nftContractAddress).supportsInterface(0x80ac58cd) ||
                IERC165(nftData.nftContractAddress).supportsInterface(
                    0xd9b67a26
                ),
            "should provide only supported interface"
        );
        if (IERC165(nftData.nftContractAddress).supportsInterface(0xd9b67a26)) {
            require(
                nftData.unit1155 > 0,
                "quantity should be greater than zero for ERC_1155 NFTS"
            );
            require(
                nftData.saleType != IDutchAuction.TypeOfSale.erc_721_nft_type,
                "invalid nft type"
            );
        }
        // the token id and token owner validation of transfer type of auction
        if (!nftData.isMint) {
            require(
                nftData.startTokenId != 0 && nftData.endTokenId != 0,
                "token start or end Id should not be 0"
            );
            require(
                nftData.endTokenId >= nftData.startTokenId,
                "listed tokens does not support"
            );
            require(
                (nftData.endTokenId - nftData.startTokenId) + 1 ==
                    nftData.noOfTokens,
                "invalid noOfTokens"
            );
            require(
                nftData.tokenOwner != address(0),
                "token Owner should not be zero"
            );
            // The token id and token owner validation of mint type of auction
        } else if (nftData.isMint) {
            if (
                nftData.saleType ==
                IDutchAuction.TypeOfSale.single_tokens_multiple_Quantity
            ) {
                require(
                    nftData.startTokenId == nftData.endTokenId,
                    "token start or end Id should be 0"
                );
            } else {
                require(
                    nftData.startTokenId == 0 && nftData.endTokenId == 0,
                    "token start or end Id should be 0"
                );
            }
            require(
                nftData.tokenOwner == address(0),
                "token Owner should be zero"
            );
        }
        // checks for walletLimit should be greater than zero
        require(nftData.walletLimit > 0, "invalid walletLimit");
        // checks for txnLimit should be greater than zero
        require(nftData.txnLimit > 0, " invalid nft limit/tnx");
        // checks for maxTokenIDRange should be greater than equal to -1.
        require(nftData.maxTokenIDRange >= -1);
        // checks whether reserve Price is less than start Price
        require(
            list.reservedPrice > 0 && list.startingPrice > list.reservedPrice,
            "invalid startPrice or reservedPrice"
        );
        // checks whether reserve Price and timeForPriceDecrement should be greater than zero
        require(
            list.reducePrice > 0 && list.timeForPriceDecrement > 0,
            "invalid reduce price and time"
        );
        // checks whether start time and end time are valid
        require(
            list.auctionStartTime >= block.timestamp &&
                list.auctionStartTime < list.auctionEndTime,
            "invalid auction start or end time"
        );
        // checks whether start time and end time are valid
        require(
            list.halfLifeTime >= list.auctionStartTime &&
                list.halfLifeTime <= list.auctionEndTime,
            "invalid halfLifeTime"
        );
        // checks whether paymentCurrency is contract address or zero address
        require(
            Address.isContract(list.paymentCurrency) ||
                list.paymentCurrency == address(0),
            "auction support only native and erc20 currency"
        );
        // checks for paymentSettlementAddress should not be zero
        require(
            list.payoutList.paymentSettlementAddress != address(0),
            "should provide settlement address"
        );
        // checks for taxSettlementAddress should not be zero
        require(
            list.payoutList.taxSettlementAddress != address(0),
            "should provide settlement address"
        );
    }

    /**
     * @notice Validation before buy in dutch Auction
     * @param dutchAuctionID the id of the created auction
     */
    function __buyValidation(
        string memory dutchAuctionID,
        address buyer,
        IDutchAuction.BuyList memory buyList
    ) external view returns (uint256 refundAmount, uint256 refundTax) {
        IDutchAuction.DutchAuctionList memory list = DutchAuction.getListings(
            dutchAuctionID
        );
        IDutchAuction.NftContractList memory nftData = list.collectionList;
        IDutchAuction.BuyerDetails memory buyerInfo = DutchAuction.getBuyerInfo(
            dutchAuctionID,
            buyer
        );

        require(initialized, "need to initialize the dutch auction");

        bytes32 leaf = keccak256(abi.encodePacked(buyer));
        // checks whether the buyer is a blacklisted buyer
        if (list.collectionList.blacklistedBuyers != bytes32(0)) {
            require(
                !MerkleProof.verify(
                    buyList.blacklistedProof,
                    list.collectionList.blacklistedBuyers,
                    leaf
                ),
                "bidder should not be a blacklisted Buyer"
            );
        }
        // checks whether the current time has crossed the start time
        require(
            list.auctionStartTime <= uint64(block.timestamp),
            "the auction has not started"
        );
        // checks whether the current time has not crossed the end time
        require(
            list.auctionEndTime > uint64(block.timestamp),
            "the auction has already ended or canceled"
        );

        // validates the discount data
        if (nftData.isSignerRequired) {
            __discountValidation(buyList.discount, buyer);
        } else if (buyList.discount.discountPercentage > 0) {
            __discountValidation(buyList.discount, buyer);
        }
        // sets current price based on discount
        uint256 currentPrice = getCurrentDutchPrice(dutchAuctionID);
        uint256 purchasePrice = 0;
        if (nftData.isDiscountRequired) {
            if (buyList.discount.discountPercentage > 0) {
                currentPrice -= ((currentPrice *
                    buyList.discount.discountPercentage) / 10000);
            }
        }

        // validates the buy data if ERC1155 - Type 1
        if (
            list.collectionList.saleType ==
            IDutchAuction.TypeOfSale.single_tokens_multiple_Quantity
        ) {
            require(
                buyList.quantity == 1 && buyList.unit1155 > 0,
                "can buy only single nft with multiple quantity"
            );
            // checks for transaction limit
            require(
                list.collectionList.txnLimit >= buyList.unit1155,
                "tnx limit exceeds"
            );
            // checks for wallet limit
            require(
                buyerInfo.totalCap + buyList.unit1155 <=
                    list.collectionList.walletLimit,
                "reached the maximum nft limit"
            );
            // checks for MaxCap
            require(
                (DutchAuction.getLatestSaleInfo(dutchAuctionID)).currentSupply +
                    buyList.unit1155 <=
                    list.collectionList.unit1155,
                "maxQauntity limit reached"
            );
            // validates the price with units and price
            require(
                buyList.price >= buyList.unit1155 * currentPrice,
                "invalid bid amount"
            );
            // updates the actual price based on the current price for given uints
            purchasePrice = buyList.unit1155 * currentPrice;
        }
        // validates the buy data if ERC721 & ERC1155 - Type 2
        else if (
            list.collectionList.saleType ==
            IDutchAuction.TypeOfSale.multiple_tokens_with_Same_Quantity ||
            list.collectionList.saleType ==
            IDutchAuction.TypeOfSale.erc_721_nft_type
        ) {
            require(
                buyList.quantity >= 1 && buyList.unit1155 == 0,
                "can buy only single nft with multiple quantity"
            );

            // checks for transaction limit
            require(
                list.collectionList.txnLimit >= buyList.quantity,
                "tnx limit exceeds"
            );
            // checks for wallet limit
            require(
                buyerInfo.totalCap + buyList.quantity <=
                    list.collectionList.walletLimit,
                "reached the maximum nft limit"
            );
            // checks for MaxCap
            require(
                (DutchAuction.getLatestSaleInfo(dutchAuctionID)).currentSupply +
                    buyList.quantity <=
                    list.collectionList.noOfTokens,
                "maxQauntity limit reached"
            );
            // validates the price with quantity and price
            require(
                buyList.price >= buyList.quantity * currentPrice,
                "invalid bid amount"
            );
            // updates the actual price based on the current price for given quantity
            purchasePrice = buyList.quantity * currentPrice;
        }

        // calculates the RefundAmount and RefundTax
        refundAmount = buyList.price - purchasePrice;
        if (buyList.discount.discountPercentage == 10000) {
            refundTax = 0;
        } else {
            uint256 taxPercentage = (buyList.tax * (10 ** 18)) / buyList.price;
            refundTax = ((refundAmount) * taxPercentage) / (10 ** 18);
        }

        if (list.paymentCurrency != address(0)) {
            // checks the buyer has sufficient amount to buy the nft
            require(
                IERC20(list.paymentCurrency).balanceOf(buyer) >=
                    purchasePrice + (buyList.tax - refundTax),
                "insufficient ERC20 funds"
            );
            // checks the buyer has provided approval for the contract to transfer the amount
            require(
                IERC20(list.paymentCurrency).allowance(
                    buyer,
                    address(DutchAuction)
                ) >= purchasePrice + (buyList.tax - refundTax),
                "insufficient approval from an ERC20 Token"
            );
        }

        //checks for collection nft approval
        if (!list.collectionList.isMint) {
            require(
                ApprovalCheck(list.collectionList.nftContractAddress)
                    .isApprovedForAll(
                        list.collectionList.tokenOwner,
                        address(DutchAuction)
                    ),
                "need collection approval"
            );
        }
    }

    /**
     * @notice Gets the current dutch auction price
     * @param dutchAuctionId the id of the created auction
     */
    function getCurrentDutchPrice(
        string memory dutchAuctionId
    ) public view returns (uint256 currentPrice) {
        IDutchAuction.DutchAuctionList memory list = DutchAuction.getListings(
            dutchAuctionId
        );
        require(initialized, "need to initialize the dutch auction");
        require(
            list.auctionEndTime >= block.timestamp &&
                list.auctionStartTime <= block.timestamp,
            "auction closed already or not started"
        );
        // sets halflife time slot
        uint256 halfTimeSlot = (list.halfLifeTime - list.auctionStartTime) /
            list.timeForPriceDecrement;
        // sets current time Slot
        uint256 currentTimeSlot = (block.timestamp - list.auctionStartTime) /
            list.timeForPriceDecrement;

        if (list.startingPrice > (currentTimeSlot * list.reducePrice)) {
            // calcualtes the current price after half life time
            if (currentTimeSlot > halfTimeSlot) {
                currentPrice =
                    (list.startingPrice - (halfTimeSlot * list.reducePrice)) /
                    (2 ** (currentTimeSlot - halfTimeSlot));
            }
            // calcualtes the current price after half life time
            else {
                currentPrice =
                    list.startingPrice -
                    (currentTimeSlot * list.reducePrice);
            }
        }
        // sets reserverd price as current price if it is lower than reserved price
        if (currentPrice < list.reservedPrice) {
            currentPrice = list.reservedPrice;
        }
    }

    /**
     * @notice Gets the dutch auction price for given timestamp
     * @param dutchAuctionId the id of the created auction
     * @param timeStamp the time stamp value to get auction price. if it is -1,returns the current price.
     */
    function getDutchAuctionPrice(
        string memory dutchAuctionId,
        int256 timeStamp
    ) public view returns (uint256 price, uint256 timeStampValue) {
        IDutchAuction.DutchAuctionList memory list = DutchAuction.getListings(
            dutchAuctionId
        );
        require(initialized, "need to initialize the dutch auction");
        require(
            DutchAuction.usedAuctionId(dutchAuctionId),
            "unsupported auction"
        );
        // gives the current price
        if (timeStamp == -1) {
            price = getCurrentDutchPrice(dutchAuctionId);
            timeStampValue = block.timestamp;
        }
        // gives the price for given timestamp
        else {
            require(
                list.auctionEndTime >= uint256(timeStamp) &&
                    list.auctionStartTime <= uint256(timeStamp),
                "auction closed already or not started"
            );
            // sets halflife time slot
            uint256 halfTimeSlot = (list.halfLifeTime - list.auctionStartTime) /
                list.timeForPriceDecrement;
            // sets current time Slot
            uint256 currentTimeSlot = (uint256(timeStamp) -
                list.auctionStartTime) / list.timeForPriceDecrement;

            if (list.startingPrice > (currentTimeSlot * list.reducePrice)) {
                // calcualtes the current price after half life time
                if (currentTimeSlot > halfTimeSlot) {
                    price =
                        (list.startingPrice -
                            (halfTimeSlot * list.reducePrice)) /
                        (2 ** (currentTimeSlot - halfTimeSlot));
                }
                // calcualtes the current price after half life time
                else {
                    price =
                        list.startingPrice -
                        (currentTimeSlot * list.reducePrice);
                }
            }
            // sets reserverd price as current price if it is lower than reserved price
            if (price < list.reservedPrice) {
                price = list.reservedPrice;
            }
            return (price, uint256(timeStamp));
        }
    }

    /**
     * @notice Gets the claimable amount in rebate type auction
     * @param dutchAuctionID the id of the created auction
     * @param buyer the address of buyer wallet
     */
    function claimable(
        string memory dutchAuctionID,
        address buyer
    ) public view returns (uint256 totalClaimable, uint256 totalTaxClaimable) {
        IDutchAuction.DutchAuctionList memory list = DutchAuction.getListings(
            dutchAuctionID
        );
        IDutchAuction.BuyerDetails memory buyerInfo = DutchAuction.getBuyerInfo(
            dutchAuctionID,
            buyer
        );
        IDutchAuction.LatestSaleDetails memory saleDetails = DutchAuction
            .getLatestSaleInfo(dutchAuctionID);

        require(initialized, "need to initialize the dutch auction");
        require(list.collectionList.isRebate, "not applicable");
        // calculates the totalClaimable and totalTaxClaimable related with discounted buy
        for (uint256 i = 0; i < buyerInfo.priceDiscount.length; i++) {
            if (
                buyerInfo.priceDiscount[i] >
                (saleDetails.finalPrice * buyerInfo.quantityDiscount[i])
            ) {
                totalClaimable +=
                    (buyerInfo.priceDiscount[i]) -
                    (saleDetails.finalPrice * buyerInfo.quantityDiscount[i]);
                // calculates the actual tax percnetage
                uint256 percentage = (buyerInfo.taxDiscount[i] * 10 ** 18) /
                    (buyerInfo.priceDiscount[i]);
                // adds the tax amount
                totalTaxClaimable +=
                    (((buyerInfo.priceDiscount[i]) -
                        (saleDetails.finalPrice *
                            buyerInfo.quantityDiscount[i])) * percentage) /
                    10 ** 18;
            }
        }

        // calculates the totalClaimable and totalTaxClaimable with zero discounted buy
        for (uint256 i = 0; i < buyerInfo.price.length; i++) {
            totalClaimable +=
                (buyerInfo.price[i]) -
                (saleDetails.finalPrice * buyerInfo.quantity[i]);
            // calculates of tax percnetage
            uint256 percentage = (buyerInfo.tax[i] * 10 ** 18) /
                (buyerInfo.price[i]);
            // adds the tax amount
            totalTaxClaimable +=
                (((buyerInfo.price[i]) -
                    (saleDetails.finalPrice * buyerInfo.quantity[i])) *
                    percentage) /
                10 ** 18;
        }
    }

    /**
     * @notice Gets the total settlement amount and tax for ending auction
     * @param dutchAuctionID the id of the created auction
     */
    function computeSettlementAmountAndTax(
        string memory dutchAuctionID
    ) external view returns (uint256 totalAmount, uint256 totalTax) {
        require(initialized, "need to initialize the Dutch Auction");

        IDutchAuction.DutchAuctionList memory list = DutchAuction.getListings(
            dutchAuctionID
        );
        IDutchAuction.NftContractList memory nftData = list.collectionList;
        address[] memory buyerAddress = DutchAuction.getBuyerAddress(
            dutchAuctionID
        );
        IDutchAuction.LatestSaleDetails memory saleDetails = DutchAuction
            .getLatestSaleInfo(dutchAuctionID);

        totalTax = 0;
        // calculates the total amount for zero discounted Tokens
        totalAmount = saleDetails.finalPrice * saleDetails.zeroDiscountSupply;

        uint256 quantityDiscount;
        for (uint256 i = 0; i < buyerAddress.length; i++) {
            address walletAddress = buyerAddress[i];
            IDutchAuction.BuyerDetails memory buyerInfo = DutchAuction
                .getBuyerInfo(dutchAuctionID, walletAddress);

            // calculates the total amount & tax for discounted related tokens
            for (uint256 j = 0; j < buyerInfo.priceDiscount.length; j++) {
                quantityDiscount += buyerInfo.quantityDiscount[j];
                // calculates the tax percnetage
                uint256 percentage = (buyerInfo.taxDiscount[j] * 10 ** 18) /
                    (buyerInfo.priceDiscount[j]);
                // adds the total settlement amount and tax amount
                if (
                    buyerInfo.priceDiscount[j] >
                    (saleDetails.finalPrice * buyerInfo.quantityDiscount[j])
                ) {
                    totalAmount += saleDetails.finalPrice;
                    if (buyerInfo.taxDiscount[j] != 0) {
                        totalTax +=
                            ((saleDetails.finalPrice *
                                buyerInfo.quantityDiscount[j]) * percentage) /
                            10 ** 18;
                    }
                } else {
                    totalAmount += buyerInfo.priceDiscount[j];
                    if (buyerInfo.taxDiscount[j] != 0) {
                        totalTax +=
                            (buyerInfo.priceDiscount[j] * percentage) /
                            10 ** 18;
                    }
                }
            }
            // calculates the tax for zero discounted tokens
            for (uint256 j = 0; j < buyerInfo.price.length; j++) {
                if (buyerInfo.tax[j] != 0) {
                    uint256 percentage = (buyerInfo.tax[j] * 10 ** 18) /
                        (buyerInfo.price[j]);
                    totalTax +=
                        ((saleDetails.finalPrice * buyerInfo.quantity[j]) *
                            percentage) /
                        10 ** 18;
                }
            }
        }
        // validates the sale before returning the values.
        require(
            saleDetails.zeroDiscountSupply +
                saleDetails.fullDiscountSupply +
                quantityDiscount ==
                saleDetails.currentSupply,
            " invalid Call"
        );
        if (nftData.isRebate) {
            if (list.paymentCurrency == address(0)) {
                require(
                    address(DutchAuction).balance >= totalAmount + totalTax,
                    "no required balance"
                );
            } else {
                require(
                    IERC20(list.paymentCurrency).balanceOf(
                        address(DutchAuction)
                    ) >= totalAmount + totalTax,
                    "no required balance"
                );
            }
        }
    }

    /**
     * @notice validtes the discount data
     * @param discount the details of discount
     * @param buyer the buyer address
     */
    function __discountValidation(
        IDutchAuction.Discount memory discount,
        address buyer
    ) internal view {
        // Checks whether that discount percentage is not more than 100
        require(
            discount.discountPercentage <= 10000,
            "the total fee basis point should be less than 10000"
        );
        // Checks whether that signer is admin of the dutch auction
        require(
            DutchAuction.isAdmin(discount.signer),
            "only owner or admin can sign for discount"
        );
        // Checks whether that signature is used already
        require(
            !DutchAuction.discountUsed(discount.signature),
            "the discount code is already used"
        );
        // Checks whether that signature is valid
        require(
            _verifySignature(buyer, discount),
            "invalid discount signature"
        );
    }

    /**
     * @notice Verifes the discount signature
     * @param buyer the buyer address
     * @param discount the details of discount
     */
    function _verifySignature(
        address buyer,
        IDutchAuction.Discount memory discount
    ) internal view returns (bool) {
        require(
            discount.expirationTime >= block.timestamp,
            "discount signature is already expired"
        );
        return
            keccak256(
                abi.encodePacked(
                    buyer,
                    discount.discountPercentage,
                    discount.expirationTime,
                    discount.nonce,
                    block.chainid
                )
            ).toEthSignedMessageHash().recover(discount.signature) ==
            discount.signer;
    }
}
