// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;
pragma abicoder v2;

import "./NiftySouq-IMarketplaceManager.sol";
import "./NiftySouq-IMarketplace.sol";
import "./NiftySouq-IERC721.sol";
import "./SafeMath.sol";
import "./Initializable.sol";
import "./SafeERC20Upgradeable.sol";

struct Bid {
    address bidder;
    uint256 price;
    uint256 bidAt;
    bool canceled;
}

struct Auction {
    uint256 tokenId;
    address tokenContract;
    uint256 startTime;
    uint256 endTime;
    address seller;
    uint256 startBidPrice;
    uint256 reservePrice;
    uint256 highestBidIdx;
    uint256 selectedBid;
    Bid[] bids;
}

struct CreateAuction {
    uint256 offerId;
    uint256 tokenId;
    address tokenContract;
    uint256 startTime;
    uint256 duration;
    address seller;
    uint256 startBidPrice;
    uint256 reservePrice;
}

struct CreateAuctionData {
    uint256 tokenId;
    address tokenContract;
    uint256 duration;
    uint256 startBidPrice;
    uint256 reservePrice;
}

struct MintAndCreateAuctionData {
    address tokenAddress;
    string uri;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
    uint256 duration;
    uint256 startBidPrice;
    uint256 reservePrice;
}

struct Payout {
    address currency;
    address[] refundAddresses;
    uint256[] refundAmounts;
}

contract NiftySouqAuctionV4 is Initializable {
    using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant PERCENT_UNIT = 1e4;
    uint256 public bidIncreasePercentage;

    address private _marketplace;
    NiftySouqIMarketplaceManager private _marketplaceManager;

    mapping(uint256 => Auction) private _auction;

    uint256 public extendAuctionPeriod;

    event eCreateAuction(
        uint256 offerId,
        uint256 tokenId,
        address contractAddress,
        address owner,
        uint256 startTime,
        uint256 duration,
        uint256 startBidPrice,
        uint256 reservePrice
    );
    event eCancelAuction(uint256 offerId);
    event eEndAuction(
        uint256 offerId,
        uint256 BidIdx,
        address buyer,
        address currency,
        uint256 price
    );
    event ePlaceBid(
        uint256 offerId,
        uint256 BidIdx,
        address bidder,
        uint256 bidAmount
    );
    event ePlaceHigherBid(
        uint256 offerId,
        uint256 BidIdx,
        address bidder,
        uint256 bidAmount
    );
    event eCancelBid(uint256 offerId, uint256 bidIdx);

    event ePayoutTransfer(
        address indexed withdrawer,
        uint256 indexed amount,
        address indexed currency
    );
    modifier isNiftyMarketplace() {
        require(
            msg.sender == _marketplace,
            "Nifty721: unauthorized. not niftysouq marketplace"
        );
        _;
    }

    function initialize(
        address marketplace_,
        address marketplaceManager_,
        uint256 bidIncreasePercentage_
    ) public initializer {
        _marketplace = marketplace_;
        _marketplaceManager = NiftySouqIMarketplaceManager(marketplaceManager_);
        bidIncreasePercentage = bidIncreasePercentage_;
    }

    function setExtendAuctionPeriod(uint256 extendAuctionPeriod_) external {
        extendAuctionPeriod = extendAuctionPeriod_;
    }

    function _createAuction(CreateAuction memory createAuctionData_) internal {
        _auction[createAuctionData_.offerId].tokenId = createAuctionData_
            .tokenId;
        _auction[createAuctionData_.offerId].tokenContract = createAuctionData_
            .tokenContract;
        _auction[createAuctionData_.offerId].startTime = createAuctionData_
            .startTime;
        _auction[createAuctionData_.offerId].endTime = createAuctionData_
            .startTime
            .add(createAuctionData_.duration);
        _auction[createAuctionData_.offerId].seller = createAuctionData_.seller;
        _auction[createAuctionData_.offerId].startBidPrice = createAuctionData_
            .startBidPrice;
        _auction[createAuctionData_.offerId].reservePrice = createAuctionData_
            .reservePrice;
    }

    function _cancelAuction(uint256 offerId)
        internal
        returns (
            address[] memory refundAddresses_,
            uint256[] memory refundAmount_
        )
    {
        refundAddresses_ = new address[](_auction[offerId].bids.length);
        refundAmount_ = new uint256[](_auction[offerId].bids.length);
        uint256 j = 0;
        for (uint256 i = 0; i < _auction[offerId].bids.length; i++) {
            Bid storage bid = _auction[offerId].bids[i];
            if (!bid.canceled) {
                refundAddresses_[j] = bid.bidder;
                refundAmount_[j] = bid.price;
                j = j.add(1);
                _auction[offerId].bids[i].canceled = true;
            }
        }
    }

    function _placeBid(
        uint256 offerId,
        address bidder,
        uint256 bidPrice
    ) internal returns (uint256 bidIdx_) {
        require(_auction[offerId].seller != bidder, "seller can not bid");
        require(
            _auction[offerId].endTime > block.timestamp,
            "Auction duration completed"
        );
        uint256 highestBidPrice = _auction[offerId].startBidPrice;

        if (_auction[offerId].bids.length > 0) {
            Bid storage highestBid = _auction[offerId].bids[
                _auction[offerId].highestBidIdx
            ];
            require(highestBid.bidder != bidder, "already bid");

            highestBidPrice = highestBid
                .price
                .mul(PERCENT_UNIT + bidIncreasePercentage)
                .div(PERCENT_UNIT);

            require(highestBidPrice > highestBid.price, "not enough bid");
        }

        require(bidPrice >= highestBidPrice, "not enough bid");

        _auction[offerId].bids.push(
            Bid({
                bidder: bidder,
                price: bidPrice,
                bidAt: block.timestamp,
                canceled: false
            })
        );

        _auction[offerId].highestBidIdx = _auction[offerId].bids.length - 1;
        bidIdx_ = _auction[offerId].highestBidIdx;
    }

    function _placeHigherBid(
        uint256 offerId,
        address bidder,
        uint256 bidIdx,
        uint256 bidPrice
    ) internal returns (uint256 currentBidPrice_) {
        require(bidIdx < _auction[offerId].bids.length, "invalid bid");
        require(
            bidder == _auction[offerId].bids[bidIdx].bidder,
            "not the bidder"
        );
        require(
            _auction[offerId].endTime > block.timestamp,
            "Auction duration completed"
        );

        Bid storage bid = _auction[offerId].bids[bidIdx];
        Bid storage highestBid = _auction[offerId].bids[
            _auction[offerId].highestBidIdx
        ];

        uint256 requiredMinBidPrice = highestBid
            .price
            .mul(PERCENT_UNIT + bidIncreasePercentage)
            .div(PERCENT_UNIT);

        require(
            bidPrice.add(bid.price) > requiredMinBidPrice,
            "not enough bid"
        );

        _auction[offerId].bids[bidIdx].price = bidPrice.add(bid.price);

        _auction[offerId].highestBidIdx = bidIdx;
        currentBidPrice_ = _auction[offerId].bids[bidIdx].price;
    }

    function _cancelBid(
        uint256 offerId,
        address bidder,
        uint256 bidIdx
    )
        internal
        returns (
            address[] memory refundAddresses_,
            uint256[] memory refundAmount_
        )
    {
        require(bidIdx < _auction[offerId].bids.length, "invalid bid");
        require(
            bidder == _auction[offerId].bids[bidIdx].bidder,
            "not a bidder"
        );
        refundAddresses_ = new address[](1);
        refundAmount_ = new uint256[](1);
        _auction[offerId].bids[bidIdx].canceled = true;
        refundAddresses_[0] = _auction[offerId].bids[bidIdx].bidder;
        refundAmount_[0] = _auction[offerId].bids[bidIdx].price;

        // update highest bidder
        if (_auction[offerId].highestBidIdx == bidIdx) {
            uint256 idx = 0;
            for (uint256 i = 0; i < _auction[offerId].bids.length; i++) {
                if (
                    !_auction[offerId].bids[i].canceled &&
                    _auction[offerId].bids[i].price >
                    _auction[offerId].bids[uint256(idx)].price
                ) {
                    idx = i;
                }
            }
            _auction[offerId].highestBidIdx = idx;
        }
    }

    function _endAuction(
        uint256 offerId_,
        // address creator,
        uint256 bidIdx
    )
        internal
        returns (
            uint256 bidAmount_,
            address[] memory recipientAddresses_,
            uint256[] memory paymentAmount_
        )
    {
        // require(creator == _auction[offerId_].seller, "not seller");
        require(bidIdx < _auction[offerId_].bids.length, "invalid bid");
        require(
            _auction[offerId_].bids[bidIdx].canceled == false,
            "bid already canceled"
        );
        require(
            _auction[offerId_].endTime < block.timestamp,
            "Auction duration not completed"
        );
        if (
            _auction[offerId_].highestBidIdx == 0 &&
            _auction[offerId_].bids[0].canceled == false
        ) return (0, new address[](0), new uint256[](0));
        uint256 offerId = offerId_;
        uint256 j = 0;

        (
            address[] memory recipientAddresses,
            uint256[] memory paymentAmount,
            ,

        ) = _marketplaceManager.calculatePayout(
                CalculatePayout(
                    _auction[offerId_].tokenId,
                    _auction[offerId_].tokenContract,
                    _auction[offerId_].seller,
                    _auction[offerId].bids[bidIdx].price,
                    1
                )
            );
        recipientAddresses_ = new address[](
            (_auction[offerId].bids.length).add(recipientAddresses.length)
        );
        paymentAmount_ = new uint256[](
            (_auction[offerId].bids.length).add(paymentAmount.length)
        );

        for (uint256 i = 0; i < recipientAddresses.length; i++) {
            recipientAddresses_[j] = recipientAddresses[i];
            if (i == recipientAddresses.length.sub(1))
                paymentAmount_[j] = paymentAmount[i].sub(
                    paymentAmount[i.sub(1)]
                );
            else paymentAmount_[j] = paymentAmount[i];
            j = j.add(1);
        }

        // refund
        {
            for (uint256 i = 0; i < _auction[offerId].bids.length; i++) {
                Bid storage bid = _auction[offerId].bids[i];
                if (i != bidIdx && !bid.canceled) {
                    recipientAddresses_[j] = bid.bidder;
                    paymentAmount_[j] = bid.price;
                    j = j.add(1);
                    _auction[offerId].bids[i].canceled = true;
                }
            }
        }

        bidAmount_ = _auction[offerId_].bids[bidIdx].price;
    }

    function _endAuctionWithHighestBid(uint256 offerId_, address caller_)
        internal
        returns (
            uint256 bidIdx_,
            uint256 bidAmount_,
            address[] memory recipientAddresses_,
            uint256[] memory paymentAmount_
        )
    {
        bidIdx_ = _auction[offerId_].highestBidIdx;
        require(
            (caller_ == _auction[offerId_].seller) ||
                (_marketplaceManager.isAdmin(caller_)),
            "NiftyMarketplace: not seller or niftysouq admin."
        );
        (bidAmount_, recipientAddresses_, paymentAmount_) = _endAuction(
            offerId_,
            // creator_,
            bidIdx_
        );
    }

    function getAuctionDetails(uint256 offerId_)
        public
        view
        returns (Auction memory auction_)
    {
        auction_ = _auction[offerId_];
    }

    function _calculatePayout(
        uint256 price_,
        uint256 serviceFeePercent_,
        uint256[] memory payouts_
    )
        internal
        view
        virtual
        returns (
            uint256 serviceFee_,
            uint256[] memory payoutFees_,
            uint256 netFee_
        )
    {
        payoutFees_ = new uint256[](payouts_.length);
        uint256 payoutSum = 0;
        serviceFee_ = percent(price_, serviceFeePercent_);

        for (uint256 i = 0; i < payouts_.length; i++) {
            uint256 royalFee = percent(price_, payouts_[i]);
            payoutFees_[i] = royalFee;
            payoutSum = payoutSum.add(royalFee);
        }

        netFee_ = price_.sub(serviceFee_).sub(payoutSum);
    }

    function percent(uint256 value_, uint256 percentage_)
        public
        pure
        virtual
        returns (uint256)
    {
        uint256 result = value_.mul(percentage_).div(PERCENT_UNIT);
        return (result);
    }

    /*************************************************************************************************************************** */
    //Create Auction
    function createAuction(CreateAuctionData memory createAuctionData_)
        public
        returns (uint256 offerId_)
    {
        (
            ContractType contractType,
            bool isERC1155,
            bool isOwner,

        ) = _marketplaceManager.isOwnerOfNFT(
                msg.sender,
                createAuctionData_.tokenId,
                createAuctionData_.tokenContract
            );
        require(isOwner, "seller not owner");
        require(!isERC1155, "cannot auction erc1155 token");

        offerId_ = NiftySouqIMarketplace(_marketplace).createSale(
            createAuctionData_.tokenId,
            NiftySouqIMarketplace.ContractType(uint256(contractType)),
            NiftySouqIMarketplace.OfferType.AUCTION
        );

        CreateAuction memory auctionData = CreateAuction(
            offerId_,
            createAuctionData_.tokenId,
            createAuctionData_.tokenContract,
            block.timestamp,
            createAuctionData_.duration,
            msg.sender,
            createAuctionData_.startBidPrice,
            createAuctionData_.reservePrice
        );
        _createAuction(auctionData);
        emit eCreateAuction(
            offerId_,
            createAuctionData_.tokenId,
            createAuctionData_.tokenContract,
            msg.sender,
            block.timestamp,
            createAuctionData_.duration,
            createAuctionData_.startBidPrice,
            createAuctionData_.reservePrice
        );
    }

    //Mint and Auction
    function mintCreateAuctionNft(
        MintAndCreateAuctionData calldata mintNCreateAuction_
    ) public returns (uint256 offerId_, uint256 tokenId_) {
        (uint256 tokenId, , address tokenAddress) = NiftySouqIMarketplace(
            _marketplace
        ).mintNft(
                NiftySouqIMarketplace.MintData(
                    msg.sender,
                    mintNCreateAuction_.tokenAddress,
                    mintNCreateAuction_.uri,
                    mintNCreateAuction_.creators,
                    mintNCreateAuction_.royalties,
                    mintNCreateAuction_.investors,
                    mintNCreateAuction_.revenues,
                    1
                )
            );

        offerId_ = createAuction(
            CreateAuctionData(
                tokenId,
                tokenAddress,
                mintNCreateAuction_.duration,
                mintNCreateAuction_.startBidPrice,
                mintNCreateAuction_.reservePrice
            )
        );
        tokenId_ = tokenId;
    }

    // //End Auction
    // function endAuction(uint256 offerId_, uint256 bidIdx_) public {
    //     NiftySouqIMarketplace.Offer memory offer = NiftySouqIMarketplace(
    //         _marketplace
    //     ).getOfferStatus(offerId_);
    //     require(
    //         offer.offerType == NiftySouqIMarketplace.OfferType.AUCTION,
    //         "offer id is not auction"
    //     );
    //     require(
    //         offer.status == NiftySouqIMarketplace.OfferState.OPEN,
    //         "auction is not active"
    //     );
    //     (
    //         uint256 bidAmount,
    //         address[] memory refundAddresses,
    //         uint256[] memory refundAmount
    //     ) = _endAuction(offerId_,
    //     // msg.sender,
    //     bidIdx_);

    //     if (refundAddresses.length > 0) {
    //         Auction memory auctionDetails = getAuctionDetails(offerId_);
    //         NiftySouqIMarketplace(_marketplace).transferNFT(
    //             auctionDetails.seller,
    //             auctionDetails.bids[bidIdx_].bidder,
    //             auctionDetails.tokenId,
    //             auctionDetails.tokenContract,
    //             1
    //         );
    //         CryptoTokens memory wethDetails = _marketplaceManager
    //             .cryptoTokenList("WETH");
    //         _payout(
    //             Payout(wethDetails.tokenAddress, refundAddresses, refundAmount)
    //         );
    //     }
    //     NiftySouqIMarketplace(_marketplace).endSale(
    //         offerId_,
    //         NiftySouqIMarketplace.OfferState.ENDED
    //     );
    //     emit eEndAuction(offerId_, bidIdx_, msg.sender, address(0), bidAmount);
    // }

    //End Auction with highest bid
    function endAuction(uint256 offerId_) public {
        NiftySouqIMarketplace.Offer memory offer = NiftySouqIMarketplace(
            _marketplace
        ).getOfferStatus(offerId_);
        require(
            offer.offerType == NiftySouqIMarketplace.OfferType.AUCTION,
            "offer id is not auction"
        );
        require(
            offer.status == NiftySouqIMarketplace.OfferState.OPEN,
            "auction is not active"
        );
        (
            uint256 bidIdx,
            uint256 bidAmount,
            address[] memory refundAddresses,
            uint256[] memory refundAmount
        ) = _endAuctionWithHighestBid(offerId_, msg.sender);
        if (refundAddresses.length > 0) {
            Auction memory auctionDetails = getAuctionDetails(offerId_);
            NiftySouqIMarketplace(_marketplace).transferNFT(
                auctionDetails.seller,
                auctionDetails.bids[bidIdx].bidder,
                auctionDetails.tokenId,
                auctionDetails.tokenContract,
                1
            );
            CryptoTokens memory wethDetails = _marketplaceManager
                .cryptoTokenList("WETH");

            _payout(
                Payout(wethDetails.tokenAddress, refundAddresses, refundAmount)
            );
        }
        NiftySouqIMarketplace(_marketplace).endSale(
            offerId_,
            NiftySouqIMarketplace.OfferState.ENDED
        );
        emit eEndAuction(offerId_, bidIdx, msg.sender, address(0), bidAmount);
    }

    //extend Auction
    function extendAuction(uint256 offerId_, uint256 duration_) public {
        NiftySouqIMarketplace.Offer memory offer = NiftySouqIMarketplace(
            _marketplace
        ).getOfferStatus(offerId_);
        require(
            offer.offerType == NiftySouqIMarketplace.OfferType.AUCTION,
            "offer id is not auction"
        );
        require(
            offer.status == NiftySouqIMarketplace.OfferState.OPEN,
            "offer is not active"
        );

        require(
            _auction[offerId_].endTime > block.timestamp,
            "Auction duration completed"
        );

        require(
            _auction[offerId_].endTime.sub(extendAuctionPeriod) < block.timestamp,
            "Not in Extend Auction duration"
        );

        require(
            _auction[offerId_].reservePrice >
                _auction[offerId_].bids[_auction[offerId_].highestBidIdx].price,
            "Cannot extend auction. already highest bid grater than reserve price"
        );
        _auction[offerId_].endTime = _auction[offerId_].endTime.add(duration_);
    }

    //Cancel Auction
    function cancelAuction(uint256 offerId_) public {
        NiftySouqIMarketplace.Offer memory offer = NiftySouqIMarketplace(
            _marketplace
        ).getOfferStatus(offerId_);
        require(
            offer.offerType == NiftySouqIMarketplace.OfferType.AUCTION,
            "offer id is not auction"
        );
        require(
            offer.status == NiftySouqIMarketplace.OfferState.OPEN,
            "offer is not active"
        );
        (
            address[] memory refundAddresses,
            uint256[] memory refundAmount
        ) = _cancelAuction(offerId_);
        CryptoTokens memory wethDetails = _marketplaceManager.cryptoTokenList(
            "WETH"
        );

        _payout(
            Payout(wethDetails.tokenAddress, refundAddresses, refundAmount)
        );

        NiftySouqIMarketplace(_marketplace).endSale(
            offerId_,
            NiftySouqIMarketplace.OfferState.ENDED
        );
        emit eCancelAuction(offerId_);
    }

    //place bid function for lazy mint token
    function lazyMintAuctionNPlaceBid(
        LazyMintAuctionData calldata lazyMintAuctionData_,
        uint256 bidPrice
    )
        public
        returns (
            uint256 offerId_,
            uint256 tokenId_,
            uint256 bidIdx_
        )
    {
        address signer = _marketplaceManager.verifyAuctionLazyMint(
            lazyMintAuctionData_
        );
        require(
            lazyMintAuctionData_.seller == signer,
            "Nifty721: signature not verified"
        );
        (ContractType contractType_, bool isERC1155_, ) = _marketplaceManager
            .getContractDetails(lazyMintAuctionData_.tokenAddress, 1);

        require(!isERC1155_, "cannot auction erc1155 token");
        require(
            (contractType_ == ContractType.NIFTY_V2 ||
                contractType_ == ContractType.COLLECTOR) && !isERC1155_,
            "Not niftysouq contract"
        );
        //mint nft

        (uint256 tokenId, , address tokenAddress) = NiftySouqIMarketplace(
            _marketplace
        ).mintNft(
                NiftySouqIMarketplace.MintData(
                    lazyMintAuctionData_.seller,
                    lazyMintAuctionData_.tokenAddress,
                    lazyMintAuctionData_.uri,
                    lazyMintAuctionData_.creators,
                    lazyMintAuctionData_.royalties,
                    lazyMintAuctionData_.investors,
                    lazyMintAuctionData_.revenues,
                    1
                )
            );
        tokenId_ = tokenId;
        //create auction
        offerId_ = NiftySouqIMarketplace(_marketplace).createSale(
            tokenId_,
            NiftySouqIMarketplace.ContractType(uint256(contractType_)),
            NiftySouqIMarketplace.OfferType.AUCTION
        );

        CreateAuction memory auctionData = CreateAuction(
            offerId_,
            tokenId_,
            tokenAddress,
            lazyMintAuctionData_.startTime,
            lazyMintAuctionData_.duration,
            lazyMintAuctionData_.seller,
            lazyMintAuctionData_.startBidPrice,
            lazyMintAuctionData_.reservePrice
        );
        _createAuction(auctionData);

        //place bid
        bidIdx_ = placeBid(offerId_, bidPrice);
    }

    //Place Bid
    function placeBid(uint256 offerId_, uint256 bidPrice_)
        public
        returns (uint256 bidIdx_)
    {
        NiftySouqIMarketplace.Offer memory offer = NiftySouqIMarketplace(
            _marketplace
        ).getOfferStatus(offerId_);
        require(
            offer.offerType == NiftySouqIMarketplace.OfferType.AUCTION,
            "offer id is not auction"
        );
        require(
            offer.status == NiftySouqIMarketplace.OfferState.OPEN,
            "offer is not active"
        );
        CryptoTokens memory wethDetails = _marketplaceManager.cryptoTokenList(
            "WETH"
        );

        IERC20Upgradeable(wethDetails.tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            bidPrice_
        );

        bidIdx_ = _placeBid(offerId_, msg.sender, bidPrice_);
        emit ePlaceBid(offerId_, bidIdx_, msg.sender, bidPrice_);
    }

    //Place Higher Bid
    function placeHigherBid(
        uint256 offerId_,
        uint256 bidIdx_,
        uint256 bidPrice_
    ) public {
        NiftySouqIMarketplace.Offer memory offer = NiftySouqIMarketplace(
            _marketplace
        ).getOfferStatus(offerId_);
        require(
            offer.offerType == NiftySouqIMarketplace.OfferType.AUCTION,
            "offer id is not auction"
        );
        require(
            offer.status == NiftySouqIMarketplace.OfferState.OPEN,
            "offer is not active"
        );
        CryptoTokens memory wethDetails = _marketplaceManager.cryptoTokenList(
            "WETH"
        );

        IERC20Upgradeable(wethDetails.tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            bidPrice_
        );

        uint256 currentBidAmount = _placeHigherBid(
            offerId_,
            msg.sender,
            bidIdx_,
            bidPrice_
        );
        emit ePlaceHigherBid(offerId_, bidIdx_, msg.sender, currentBidAmount);
    }

    //Cancel Bid
    function cancelBid(uint256 offerId_, uint256 bidIdx_) public {
        NiftySouqIMarketplace.Offer memory offer = NiftySouqIMarketplace(
            _marketplace
        ).getOfferStatus(offerId_);
        require(
            offer.offerType == NiftySouqIMarketplace.OfferType.AUCTION,
            "offer id is not auction"
        );
        require(
            offer.status == NiftySouqIMarketplace.OfferState.OPEN,
            "offer is not active"
        );
        (
            address[] memory refundAddresses,
            uint256[] memory refundAmount
        ) = _cancelBid(offerId_, msg.sender, bidIdx_);
        CryptoTokens memory wethDetails = _marketplaceManager.cryptoTokenList(
            "WETH"
        );

        _payout(
            Payout(wethDetails.tokenAddress, refundAddresses, refundAmount)
        );
        emit eCancelBid(offerId_, bidIdx_);
    }

    function _payout(Payout memory payoutData_) private {
        for (uint256 i = 0; i < payoutData_.refundAddresses.length; i++) {
            if (payoutData_.refundAddresses[i] != address(0)) {
                if (address(0) == payoutData_.currency) {
                    payable(payoutData_.refundAddresses[i]).transfer(
                        payoutData_.refundAmounts[i]
                    );
                } else {
                    IERC20Upgradeable(payoutData_.currency).safeTransfer(
                        payoutData_.refundAddresses[i],
                        payoutData_.refundAmounts[i]
                    );
                }
                emit ePayoutTransfer(
                    payoutData_.refundAddresses[i],
                    payoutData_.refundAmounts[i],
                    payoutData_.currency
                );
            }
        }
    }
}
