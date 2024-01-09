// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ISuperRareAuctionHouse.sol";
import "./SuperRareBazaarBase.sol";

/// @author koloz
/// @title SuperRareAuctionHouse
/// @notice The logic for all functions related to the SuperRareAuctionHouse.
contract SuperRareAuctionHouse is
    ISuperRareAuctionHouse,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    SuperRareBazaarBase
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /////////////////////////////////////////////////////////////////////////
    // Initializer
    /////////////////////////////////////////////////////////////////////////
    function initialize(
        address _marketplaceSettings,
        address _royaltyRegistry,
        address _royaltyEngine,
        address _spaceOperatorRegistry,
        address _approvedTokenRegistry,
        address _payments,
        address _stakingRegistry,
        address _networkBeneficiary
    ) public initializer {
        require(_marketplaceSettings != address(0));
        require(_royaltyRegistry != address(0));
        require(_royaltyEngine != address(0));
        require(_spaceOperatorRegistry != address(0));
        require(_approvedTokenRegistry != address(0));
        require(_payments != address(0));
        require(_networkBeneficiary != address(0));

        marketplaceSettings = IMarketplaceSettings(_marketplaceSettings);
        royaltyRegistry = IERC721CreatorRoyalty(_royaltyRegistry);
        royaltyEngine = IRoyaltyEngineV1(_royaltyEngine);
        spaceOperatorRegistry = ISpaceOperatorRegistry(_spaceOperatorRegistry);
        approvedTokenRegistry = IApprovedTokenRegistry(_approvedTokenRegistry);
        payments = IPayments(_payments);
        stakingRegistry = _stakingRegistry;
        networkBeneficiary = _networkBeneficiary;

        minimumBidIncreasePercentage = 10;
        maxAuctionLength = 7 days;
        auctionLengthExtension = 15 minutes;
        offerCancelationDelay = 5 minutes;

        __Ownable_init();
        __ReentrancyGuard_init();
    }

    /// @notice Configures an Auction for a given asset.
    /// @dev If auction type is coldie (reserve) then _startingAmount cant be 0.
    /// @dev _currencyAddress equal to the zero address denotes eth.
    /// @dev All time related params are unix epoch timestamps.
    /// @param _auctionType The type of auction being configured.
    /// @param _originContract Contract address of the asset being put up for auction.
    /// @param _tokenId Token Id of the asset.
    /// @param _startingAmount The reserve price or min bid of an auction.
    /// @param _currencyAddress The currency the auction is being conducted in.
    /// @param _lengthOfAuction The amount of time in seconds that the auction is configured for.
    /// @param _splitAddresses Addresses to split the sellers commission with.
    /// @param _splitRatios The ratio for the split corresponding to each of the addresses being split with.
    function configureAuction(
        bytes32 _auctionType,
        address _originContract,
        uint256 _tokenId,
        uint256 _startingAmount,
        address _currencyAddress,
        uint256 _lengthOfAuction,
        uint256 _startTime,
        address payable[] calldata _splitAddresses,
        uint8[] calldata _splitRatios
    ) external override {
        _checkIfCurrencyIsApproved(_currencyAddress);
        _senderMustBeTokenOwner(_originContract, _tokenId);
        _ownerMustHaveMarketplaceApprovedForNFT(_originContract, _tokenId);
        _checkSplits(_splitAddresses, _splitRatios);
        _checkValidAuctionType(_auctionType);

        require(
            _lengthOfAuction <= maxAuctionLength,
            "configureAuction::Auction too long."
        );

        Auction memory auction = tokenAuctions[_originContract][_tokenId];

        require(
            auction.auctionType == NO_AUCTION ||
                auction.auctionCreator != msg.sender,
            "configureAuction::Cannot have a current auction."
        );

        require(_lengthOfAuction > 0, "configureAuction::Length must be > 0");

        if (_auctionType == COLDIE_AUCTION) {
            require(
                _startingAmount > 0,
                "configureAuction::Coldie starting price must be > 0"
            );
        } else if (_auctionType == SCHEDULED_AUCTION) {
            require(
                _startTime > block.timestamp,
                "configureAuction::Scheduled auction cannot start in past."
            );
        }

        require(
            _startingAmount <= marketplaceSettings.getMarketplaceMaxValue(),
            "configureAuction::Cannot set starting price higher than max value."
        );

        tokenAuctions[_originContract][_tokenId] = Auction(
            msg.sender,
            block.number,
            _auctionType == COLDIE_AUCTION ? 0 : _startTime,
            _lengthOfAuction,
            _currencyAddress,
            _startingAmount,
            _auctionType,
            _splitAddresses,
            _splitRatios
        );

        if (_auctionType == SCHEDULED_AUCTION) {
            IERC721 erc721 = IERC721(_originContract);
            erc721.transferFrom(msg.sender, address(this), _tokenId);
        }

        emit NewAuction(
            _originContract,
            _tokenId,
            msg.sender,
            _currencyAddress,
            _startTime,
            _startingAmount,
            _lengthOfAuction
        );
    }

    /// @notice Converts an offer into a coldie auction.
    /// @param _originContract Contract address of the asset.
    /// @dev Covers use of any currency (0 address is eth).
    /// @dev Only covers converting an offer to a coldie auction.
    /// @dev Cant convert offer if an auction currently exists.
    /// @param _tokenId Token Id of the asset.
    /// @param _currencyAddress Address of the currency being converted.
    /// @param _amount Amount being converted into an auction.
    /// @param _lengthOfAuction Number of seconds the auction will last.
    /// @param _splitAddresses Addresses that the sellers take in will be split amongst.
    /// @param _splitRatios Ratios that the take in will be split by.
    function convertOfferToAuction(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount,
        uint256 _lengthOfAuction,
        address payable[] calldata _splitAddresses,
        uint8[] calldata _splitRatios
    ) external override {
        _senderMustBeTokenOwner(_originContract, _tokenId);
        _ownerMustHaveMarketplaceApprovedForNFT(_originContract, _tokenId);
        _checkSplits(_splitAddresses, _splitRatios);

        Auction memory auction = tokenAuctions[_originContract][_tokenId];

        require(
            auction.auctionType == NO_AUCTION ||
                auction.auctionCreator != msg.sender,
            "convertOfferToAuction::Cannot have a current auction."
        );

        require(
            _lengthOfAuction <= maxAuctionLength,
            "convertOfferToAuction::Auction too long."
        );

        Offer memory currOffer = tokenCurrentOffers[_originContract][_tokenId][
            _currencyAddress
        ];

        require(currOffer.buyer != msg.sender, "convert::own offer");

        require(
            currOffer.convertible,
            "convertOfferToAuction::Offer is not convertible"
        );

        require(
            currOffer.amount == _amount,
            "convertOfferToAuction::Converting offer with different amount."
        );

        tokenAuctions[_originContract][_tokenId] = Auction(
            msg.sender,
            block.number,
            block.timestamp,
            _lengthOfAuction,
            _currencyAddress,
            currOffer.amount,
            COLDIE_AUCTION,
            _splitAddresses,
            _splitRatios
        );

        delete tokenCurrentOffers[_originContract][_tokenId][_currencyAddress];

        auctionBids[_originContract][_tokenId] = Bid(
            currOffer.buyer,
            _currencyAddress,
            _amount,
            marketplaceSettings.getMarketplaceFeePercentage()
        );

        IERC721 erc721 = IERC721(_originContract);
        erc721.transferFrom(msg.sender, address(this), _tokenId);

        emit NewAuction(
            _originContract,
            _tokenId,
            msg.sender,
            _currencyAddress,
            block.timestamp,
            _amount,
            _lengthOfAuction
        );

        emit AuctionBid(
            _originContract,
            currOffer.buyer,
            _tokenId,
            _currencyAddress,
            _amount,
            true,
            0,
            address(0)
        );
    }

    /// @notice Cancels a configured Auction that has not started.
    /// @dev Requires the person sending the message to be the auction creator or token owner.
    /// @param _originContract Contract address of the asset pending auction.
    /// @param _tokenId Token Id of the asset.
    function cancelAuction(address _originContract, uint256 _tokenId)
        external
        override
    {
        Auction memory auction = tokenAuctions[_originContract][_tokenId];

        IERC721 erc721 = IERC721(_originContract);

        require(
            auction.auctionType != NO_AUCTION,
            "cancelAuction::Must have an auction configured."
        );

        require(
            auction.startingTime == 0 || block.timestamp < auction.startingTime,
            "cancelAuction::Auction must not have started."
        );

        require(
            auction.auctionCreator == msg.sender ||
                erc721.ownerOf(_tokenId) == msg.sender,
            "cancelAuction::Must be creator or owner."
        );

        delete tokenAuctions[_originContract][_tokenId];

        if (erc721.ownerOf(_tokenId) == address(this)) {
            erc721.transferFrom(address(this), msg.sender, _tokenId);
        }

        emit CancelAuction(_originContract, _tokenId, auction.auctionCreator);
    }

    /// @notice Places a bid on a valid auction.
    /// @dev Only the configured currency can be used (Zero address for eth)
    /// @param _originContract Contract address of asset being bid on.
    /// @param _tokenId Token Id of the asset.
    /// @param _currencyAddress Address of currency being used to bid.
    /// @param _amount Amount of the currency being used for the bid.
    function bid(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount
    ) external payable override nonReentrant {
        uint256 requiredAmount = _amount.add(
            marketplaceSettings.calculateMarketplaceFee(_amount)
        );

        _senderMustHaveMarketplaceApproved(_currencyAddress, requiredAmount);

        Auction memory auction = tokenAuctions[_originContract][_tokenId];

        require(
            auction.auctionType != NO_AUCTION,
            "bid::Must have a current auction."
        );

        require(
            auction.auctionCreator != msg.sender,
            "bid::Cannot bid on your own auction."
        );

        require(
            block.timestamp >= auction.startingTime,
            "bid::Auction not active."
        );

        require(
            _currencyAddress == auction.currencyAddress,
            "bid::Currency must be in configured denomination"
        );

        require(_amount > 0, "bid::Cannot be 0");

        require(
            _amount <= marketplaceSettings.getMarketplaceMaxValue(),
            "bid::Must be less than max value."
        );

        require(
            _amount >= auction.minimumBid,
            "bid::Cannot be lower than minimum bid."
        );

        require(
            auction.startingTime == 0 ||
                block.timestamp <
                auction.startingTime.add(auction.lengthOfAuction),
            "bid::Must be active."
        );

        Bid memory currBid = auctionBids[_originContract][_tokenId];

        require(
            _amount >=
                currBid.amount.add(
                    currBid.amount.mul(minimumBidIncreasePercentage).div(100)
                ),
            "bid::Must be higher than prev bid + min increase."
        );

        IERC721 erc721 = IERC721(_originContract);
        address tokenOwner = erc721.ownerOf(_tokenId);

        require(
            auction.auctionCreator == tokenOwner || tokenOwner == address(this),
            "bid::Auction creator must be owner."
        );

        if (auction.auctionCreator == tokenOwner) {
            _ownerMustHaveMarketplaceApprovedForNFT(_originContract, _tokenId);
        }

        _checkAmountAndTransfer(_currencyAddress, requiredAmount);

        _refund(
            _currencyAddress,
            currBid.amount,
            currBid.marketplaceFee,
            currBid.bidder
        );

        auctionBids[_originContract][_tokenId] = Bid(
            msg.sender,
            _currencyAddress,
            _amount,
            marketplaceSettings.getMarketplaceFeePercentage()
        );

        bool startedAuction = false;
        uint256 newAuctionLength = 0;

        if (auction.startingTime == 0) {
            tokenAuctions[_originContract][_tokenId].startingTime = block
                .timestamp;

            erc721.transferFrom(
                auction.auctionCreator,
                address(this),
                _tokenId
            );

            startedAuction = true;
        } else if (
            auction.startingTime.add(auction.lengthOfAuction).sub(
                block.timestamp
            ) < auctionLengthExtension
        ) {
            newAuctionLength = block.timestamp.add(auctionLengthExtension).sub(
                auction.startingTime
            );

            tokenAuctions[_originContract][_tokenId]
                .lengthOfAuction = newAuctionLength;
        }

        emit AuctionBid(
            _originContract,
            msg.sender,
            _tokenId,
            _currencyAddress,
            _amount,
            startedAuction,
            newAuctionLength,
            currBid.bidder
        );
    }

    /// @notice Settles an auction that has ended.
    /// @dev Anyone is able to settle an auction since non-input params are used.
    /// @param _originContract Contract address of asset.
    /// @param _tokenId Token Id of the asset.
    function settleAuction(address _originContract, uint256 _tokenId)
        external
        override
    {
        Auction memory auction = tokenAuctions[_originContract][_tokenId];

        require(
            auction.auctionType != NO_AUCTION && auction.startingTime != 0,
            "settleAuction::Must have a current valid auction."
        );

        require(
            block.timestamp >=
                auction.startingTime.add(auction.lengthOfAuction),
            "settleAuction::Can only settle ended auctions."
        );

        Bid memory currBid = auctionBids[_originContract][_tokenId];

        delete tokenAuctions[_originContract][_tokenId];
        delete auctionBids[_originContract][_tokenId];

        IERC721 erc721 = IERC721(_originContract);

        if (currBid.bidder == address(0)) {
            erc721.transferFrom(
                address(this),
                auction.auctionCreator,
                _tokenId
            );
        } else {
            erc721.transferFrom(address(this), currBid.bidder, _tokenId);

            _payout(
                _originContract,
                _tokenId,
                auction.currencyAddress,
                currBid.amount,
                auction.auctionCreator,
                auction.splitRecipients,
                auction.splitRatios
            );

            marketplaceSettings.markERC721Token(
                _originContract,
                _tokenId,
                true
            );
        }

        emit AuctionSettled(
            _originContract,
            currBid.bidder,
            auction.auctionCreator,
            _tokenId,
            auction.currencyAddress,
            currBid.amount
        );
    }

    /// @notice Grabs the current auction details for a token.
    /// @param _originContract Contract address of asset.
    /// @param _tokenId Token Id of the asset.
    /** @return Auction Struct: creatorAddress, creationTime, startingTime, lengthOfAuction,
                currencyAddress, minimumBid, auctionType, splitRecipients array, and splitRatios array.
    */
    function getAuctionDetails(address _originContract, uint256 _tokenId)
        external
        view
        override
        returns (
            address,
            uint256,
            uint256,
            uint256,
            address,
            uint256,
            bytes32,
            address payable[] memory,
            uint8[] memory
        )
    {
        Auction memory auction = tokenAuctions[_originContract][_tokenId];

        return (
            auction.auctionCreator,
            auction.creationBlock,
            auction.startingTime,
            auction.lengthOfAuction,
            auction.currencyAddress,
            auction.minimumBid,
            auction.auctionType,
            auction.splitRecipients,
            auction.splitRatios
        );
    }

    function _checkValidAuctionType(bytes32 _auctionType) internal pure {
        if (
            _auctionType != COLDIE_AUCTION && _auctionType != SCHEDULED_AUCTION
        ) {
            revert("Invalid Auction Type");
        }
    }
}
