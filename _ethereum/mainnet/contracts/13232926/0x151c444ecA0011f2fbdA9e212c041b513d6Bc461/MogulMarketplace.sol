// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "./IERC1155.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC1155Holder.sol";
import "./AccessControl.sol";
import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";

contract MogulMarketplace is ERC1155Holder, AccessControl, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");
    address payable public treasuryWallet;
    IERC20 stars;
    uint256 public nextListingId;
    uint256 public nextAuctionId;
    uint256 public feeBasisPoint; //4 decimals, applies to auctions and listings. Fees collected are held in contract
    uint256 public adminEth; //Total Ether available for withdrawal
    uint256 public adminStars; //Total Stars available for withdrawal
    uint256 private highestCommissionBasisPoint; //Used to determine what the maximum fee
    bool public starsAllowed;

    struct Listing {
        address payable seller;
        address tokenAddress;
        uint256 tokenId;
        uint256 tokenAmount;
        uint256 price;
        bool isStarsListing;
    }

    struct Auction {
        address payable seller;
        address tokenAddress;
        uint256 tokenId;
        uint256 tokenAmount;
        uint256 startingPrice;
        uint256 startTime;
        uint256 endTime;
        bool isStarsAuction;
        Bid highestBid;
    }

    struct Bid {
        address payable bidder;
        uint256 amount;
    }

    struct TokenCommissionInfo {
        address payable artistAddress;
        uint256 commissionBasisPoint; //4 decimals
    }

    EnumerableSet.AddressSet private mogulNFTs;
    EnumerableSet.UintSet private listingIds;
    EnumerableSet.UintSet private auctionIds;

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => Auction) public auctions;
    mapping(address => mapping(uint256 => TokenCommissionInfo))
        public commissions; //NFT address to (token ID to TokenCommissionInfo)

    event ListingCreated(
        uint256 listingId,
        address seller,
        address tokenAddress,
        uint256 tokenId,
        uint256 tokenAmount,
        uint256 price,
        bool isStarsListing
    );
    event ListingCancelled(uint256 listingId);
    event ListingPriceChanged(uint256 listingId, uint256 newPrice);
    event AuctionCreated(
        uint256 auctionId,
        address seller,
        address tokenAddress,
        uint256 tokenId,
        uint256 tokenAmount,
        uint256 startingPrice,
        uint256 startTime,
        uint256 endTime,
        bool isStarsAuction
    );
    event SaleMade(address buyer, uint256 listingId, uint256 amount);
    event BidPlaced(
        address bidder,
        uint256 auctionId,
        uint256 amount,
        bool isStarsBid
    );
    event AuctionClaimed(address winner, uint256 auctionId);
    event AuctionCancelled(uint256 auctionId);
    event TokenCommissionSingleAdded(
        address tokenAddress,
        uint256 tokenId,
        address artistAddress,
        uint256 commissionBasisPoint
    );
    event TokenCommissionBulkAdded(
        address tokenAddress,
        uint256[] tokenIds,
        address payable[] artistAddresses,
        uint256[] commissionBasisPoints
    );

    modifier onlyAdmin {
        require(hasRole(ROLE_ADMIN, msg.sender), "Sender is not admin");
        _;
    }

    modifier sellerOrAdmin(address seller) {
        require(
            msg.sender == seller || hasRole(ROLE_ADMIN, msg.sender),
            "Sender is not seller or admin"
        );
        _;
    }

    /**
     * @dev Stores the Stars contract, and allows users with the admin role to
     * grant/revoke the admin role from other users. Stores treasury wallet.
     *
     * Params:
     * starsAddress: the address of the Stars contract
     * _admin: address of the first admin
     * _treasuryWallet: address of treasury wallet
     */
    constructor(
        address starsAddress,
        address _admin,
        address payable _treasuryWallet,
        address _mogulNFTAddress
    ) {
        require(
            _treasuryWallet != address(0),
            "Treasury wallet cannot be 0 address"
        );
        _setupRole(ROLE_ADMIN, _admin);
        _setRoleAdmin(ROLE_ADMIN, ROLE_ADMIN);

        treasuryWallet = _treasuryWallet;
        stars = IERC20(starsAddress);

        mogulNFTs.add(_mogulNFTAddress);
    }

    //Allows contract to inherit both ERC1155Receiver and AccessControl
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Receiver, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(ERC1155Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    //Get number of listings
    function getNumListings() external view returns (uint256) {
        return listingIds.length();
    }

    /**
     * @dev Get listing ID at index
     *
     * Params:
     * indices: indices of IDs
     */
    function getListingIds(uint256[] memory indices)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory output = new uint256[](indices.length);
        for (uint256 i = 0; i < indices.length; i++) {
            output[i] = listingIds.at(indices[i]);
        }
        return output;
    }

    /**
     * @dev Get listing correlated to index
     *
     * Params:
     * indices: indices of IDs
     */
    function getListingsAtIndices(uint256[] memory indices)
        external
        view
        returns (Listing[] memory)
    {
        Listing[] memory output = new Listing[](indices.length);
        for (uint256 i = 0; i < indices.length; i++) {
            output[i] = listings[listingIds.at(indices[i])];
        }
        return output;
    }

    //Get number of auctions
    function getNumAuctions() external view returns (uint256) {
        return auctionIds.length();
    }

    /**
     * @dev Get auction ID at index
     *
     * Params:
     * indices: indices of IDs
     */
    function getAuctionIds(uint256[] memory indices)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory output = new uint256[](indices.length);
        for (uint256 i = 0; i < indices.length; i++) {
            output[i] = auctionIds.at(indices[i]);
        }
        return output;
    }

    /**
     * @dev Get auction correlated to index
     *
     * Params:
     * indices: indices of IDs
     */
    function getAuctionsAtIndices(uint256[] memory indices)
        external
        view
        returns (Auction[] memory)
    {
        Auction[] memory output = new Auction[](indices.length);
        for (uint256 i = 0; i < indices.length; i++) {
            output[i] = auctions[auctionIds.at(indices[i])];
        }
        return output;
    }

    /**
     * @dev Get commission info for array of tokens
     *
     * Params:
     * NFTAddress: address of NFT
     * tokenIds: token IDs
     */
    function getCommissionInfoForTokens(
        address NFTAddress,
        uint256[] memory tokenIds
    ) external view returns (TokenCommissionInfo[] memory) {
        TokenCommissionInfo[] memory output =
            new TokenCommissionInfo[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            output[i] = commissions[NFTAddress][tokenIds[i]];
        }
        return output;
    }

    /**
     * @dev Create a new listing
     *
     * Params:
     * tokenAddress: address of token to list
     * tokenId: id of token
     * tokenAmount: number of tokens
     * price: listing price
     * isStarsListing: whether or not the listing is sold for Stars
     */
    function createListing(
        address tokenAddress,
        uint256 tokenId,
        uint256 tokenAmount,
        uint256 price,
        bool isStarsListing
    ) public nonReentrant() {
        require(
            mogulNFTs.contains(tokenAddress),
            "Only Mogul NFTs can be listed"
        );
        require(price != 0, "Price cannot be 0");
        require(tokenAmount != 0, "Cannot list 0 tokens");

        if (isStarsListing) {
            require(starsAllowed, "Stars listings are not allowed");
        }

        IERC1155 token = IERC1155(tokenAddress);
        token.safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            tokenAmount,
            ""
        );
        uint256 listingId = generateListingId();
        listings[listingId] = Listing(
            payable(msg.sender),
            tokenAddress,
            tokenId,
            tokenAmount,
            price,
            isStarsListing
        );
        listingIds.add(listingId);

        emit ListingCreated(
            listingId,
            msg.sender,
            tokenAddress,
            tokenId,
            tokenAmount,
            price,
            isStarsListing
        );
    }

    /**
     * @dev Batch create new listings
     *
     * Params:
     * tokenAddresses: addresses of tokens to list
     * tokenIds: id of each token
     * tokenAmounts: amount of each token to list
     * prices: price of each listing
     * areStarsListings: whether or not each listing is sold for Stars
     *
     * Requirements:
     * - All inputs are the same length
     */
    function batchCreateListings(
        address[] calldata tokenAddresses,
        uint256[] calldata tokenIds,
        uint256[] calldata tokenAmounts,
        uint256[] calldata prices,
        bool[] calldata areStarsListings
    ) external onlyAdmin {
        require(
            tokenAddresses.length == tokenIds.length &&
                tokenIds.length == tokenAmounts.length &&
                tokenAmounts.length == prices.length &&
                prices.length == areStarsListings.length,
            "Incorrect input lengths"
        );
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            createListing(
                tokenAddresses[i],
                tokenIds[i],
                tokenAmounts[i],
                prices[i],
                areStarsListings[i]
            );
        }
    }

    /**
     * @dev Cancel a listing
     *
     * Params:
     * listingId: listing ID
     */
    function cancelListing(uint256 listingId)
        external
        sellerOrAdmin(listings[listingId].seller)
        nonReentrant()
    {
        require(listingIds.contains(listingId), "Listing does not exist");
        Listing storage listing = listings[listingId];

        listingIds.remove(listingId);

        IERC1155 token = IERC1155(listing.tokenAddress);
        token.safeTransferFrom(
            address(this),
            listing.seller,
            listing.tokenId,
            listing.tokenAmount,
            ""
        );
        emit ListingCancelled(listingId);
    }

    /**
     * @dev Change price of a listing
     *
     * Params:
     * listingId: listing ID
     * newPrice: price to change to
     */
    function changeListingPrice(uint256 listingId, uint256 newPrice)
        external
        sellerOrAdmin(listings[listingId].seller)
    {
        require(newPrice != 0, "Price cannot be 0");
        listings[listingId].price = newPrice;

        emit ListingPriceChanged(listingId, newPrice);
    }

    /**
     * @dev Buy a token
     *
     * Params:
     * listingId: listing ID
     * amount: amount tokens to buy
     */
    function buyTokens(
        uint256 listingId,
        uint256 amount,
        uint256 expectedPrice
    ) external payable nonReentrant() {
        require(listingIds.contains(listingId), "Listing does not exist.");

        Listing storage listing = listings[listingId];

        require(listing.tokenAmount >= amount, "Not enough tokens remaining");

        uint256 fullAmount = listing.price * amount;
        require(fullAmount == expectedPrice, "Incorrect expected price");

        uint256 fee = (fullAmount * feeBasisPoint) / 10000;
        uint256 commission =
            (fullAmount *
                commissions[listing.tokenAddress][listing.tokenId]
                    .commissionBasisPoint) / 10000;

        if (listing.isStarsListing) {
            stars.safeTransferFrom(msg.sender, address(this), fee);

            if (
                commissions[listing.tokenAddress][listing.tokenId]
                    .artistAddress != address(0)
            ) {
                stars.safeTransferFrom(
                    msg.sender,
                    commissions[listing.tokenAddress][listing.tokenId]
                        .artistAddress,
                    commission
                );
            }

            stars.safeTransferFrom(
                msg.sender,
                listing.seller,
                fullAmount - fee - commission
            );

            adminStars += fee;
        } else {
            require(msg.value == fullAmount, "Incorrect transaction value");

            (bool success, ) =
                listing.seller.call{value: fullAmount - fee - commission}("");
            require(success, "Payment failure");

            if (
                commissions[listing.tokenAddress][listing.tokenId]
                    .artistAddress != address(0)
            ) {
                (success, ) = commissions[listing.tokenAddress][listing.tokenId]
                    .artistAddress
                    .call{value: commission}("");

                require(success, "Payment failure");
            }

            adminEth += fee;
        }

        listing.tokenAmount -= amount;

        if (listing.tokenAmount == 0) {
            listingIds.remove(listingId);
        }

        IERC1155 token = IERC1155(listing.tokenAddress);
        token.safeTransferFrom(
            address(this),
            msg.sender,
            listing.tokenId,
            amount,
            ""
        );

        emit SaleMade(msg.sender, listingId, amount);
    }

    /**
     * @dev Create an auction
     *
     * Params:
     * tokenAddress: address of token
     * tokenId: token ID
     * tokenAmount: number of tokens the winner will get
     * startingPrice: starting price for bids
     * startTime: auction start time
     * endTime: auction end time
     * isStarsAuction: whether or not Auction is in Stars
     */
    function createAuction(
        address tokenAddress,
        uint256 tokenId,
        uint256 tokenAmount,
        uint256 startingPrice,
        uint256 startTime,
        uint256 endTime,
        bool isStarsAuction
    ) public nonReentrant() {
        require(startTime < endTime, "End time must be after start time");
        require(
            startTime > block.timestamp,
            "Auction must start in the future"
        );
        require(
            mogulNFTs.contains(tokenAddress),
            "Only Mogul NFTs can be listed"
        );
        require(tokenAmount != 0, "Cannot auction 0 tokens");
        if (isStarsAuction) {
            require(starsAllowed, "Stars auctions are not allowed");
        }

        IERC1155 token = IERC1155(tokenAddress);
        token.safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            tokenAmount,
            ""
        );

        uint256 auctionId = generateAuctionId();
        auctions[auctionId] = Auction(
            payable(msg.sender),
            tokenAddress,
            tokenId,
            tokenAmount,
            startingPrice,
            startTime,
            endTime,
            isStarsAuction,
            Bid(payable(msg.sender), 0)
        );
        auctionIds.add(auctionId);
        emit AuctionCreated(
            auctionId,
            payable(msg.sender),
            tokenAddress,
            tokenId,
            tokenAmount,
            startingPrice,
            startTime,
            endTime,
            isStarsAuction
        );
    }

    /**
     * @dev Batch create new auctions
     *
     * Params:
     * tokenAddresses: addresses of tokens to auction
     * tokenIds: id of each token
     * tokenAmounts: amount of each token to auction
     * startingPrices: starting price of each auction
     * startTimes: start time of each auction
     * endTimes: end time of each auction
     * areStarsAuctions: whether or not each auction is in Stars
     *
     * Requirements:
     * - All inputs are the same length
     */
    function batchCreateAuctions(
        address[] calldata tokenAddresses,
        uint256[] calldata tokenIds,
        uint256[] calldata tokenAmounts,
        uint256[] calldata startingPrices,
        uint256[] calldata startTimes,
        uint256[] memory endTimes,
        bool[] memory areStarsAuctions
    ) external onlyAdmin {
        require(
            tokenAddresses.length == tokenIds.length &&
                tokenIds.length == tokenAmounts.length &&
                tokenAmounts.length == startingPrices.length &&
                startingPrices.length == startTimes.length &&
                startTimes.length == endTimes.length &&
                endTimes.length == areStarsAuctions.length,
            "Incorrect input lengths"
        );
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            createAuction(
                tokenAddresses[i],
                tokenIds[i],
                tokenAmounts[i],
                startingPrices[i],
                startTimes[i],
                endTimes[i],
                areStarsAuctions[i]
            );
        }
    }

    /**
     * @dev Place a bid and refund the previous highest bidder
     *
     * Params:
     * auctionId: auction ID
     * isStarsBid: true if bid is in Stars, false if it's in eth
     * amount: amount of bid
     *
     * Requirements:
     * Bid is higher than the previous highest bid
     */
    function placeBid(uint256 auctionId, uint256 amount)
        external
        payable
        nonReentrant()
    {
        require(auctionIds.contains(auctionId), "Auction does not exist.");

        Auction storage auction = auctions[auctionId];
        require(
            block.timestamp >= auction.startTime,
            "Auction has not started yet"
        );

        require(block.timestamp <= auction.endTime, "Auction has ended");

        require(
            amount > auction.highestBid.amount,
            "Bid is lower than highest bid"
        );

        require(
            amount > auction.startingPrice,
            "Bid is lower than starting price"
        );

        if (auction.isStarsAuction) {
            stars.safeTransferFrom(msg.sender, address(this), amount);
            stars.safeTransfer(
                auction.highestBid.bidder,
                auction.highestBid.amount
            );
            auction.highestBid = Bid(payable(msg.sender), amount);
        } else {
            require(amount == msg.value, "Amount does not match message value");
            (bool success, ) =
                auction.highestBid.bidder.call{
                    value: auction.highestBid.amount
                }("");
            require(success, "Payment failure");
            auction.highestBid = Bid(payable(msg.sender), amount);
        }

        emit BidPlaced(msg.sender, auctionId, amount, auction.isStarsAuction);
    }

    /**
     * @dev End auctions and distributes tokens to the winner, bid to the
     * seller, and fees to the contract
     *
     * Params:
     * auctionId: auction ID
     */
    function claimAuction(uint256 auctionId) external nonReentrant() {
        require(auctionIds.contains(auctionId), "Auction does not exist");
        Auction memory auction = auctions[auctionId];
        require(block.timestamp >= auction.endTime, "Auction is ongoing");
        address winner;

        uint256 fee = (auction.highestBid.amount * feeBasisPoint) / 10000;
        uint256 commission =
            (auction.highestBid.amount *
                commissions[auction.tokenAddress][auction.tokenId]
                    .commissionBasisPoint) / 10000;

        winner = auction.highestBid.bidder;
        if (auction.isStarsAuction) {
            stars.safeTransfer(
                auction.seller,
                auction.highestBid.amount - fee - commission
            );

            if (
                commissions[auction.tokenAddress][auction.tokenId]
                    .artistAddress != address(0)
            ) {
                stars.safeTransfer(
                    commissions[auction.tokenAddress][auction.tokenId]
                        .artistAddress,
                    commission
                );
            }

            adminStars += fee;
        } else {
            (bool success, ) =
                auction.seller.call{
                    value: auction.highestBid.amount - fee - commission
                }("");

            require(success, "Payment failure");

            if (
                commissions[auction.tokenAddress][auction.tokenId]
                    .artistAddress != address(0)
            ) {
                (success, ) = commissions[auction.tokenAddress][auction.tokenId]
                    .artistAddress
                    .call{value: commission}("");

                require(success, "Payment failure");
            }

            adminEth += fee;
        }

        IERC1155(auction.tokenAddress).safeTransferFrom(
            address(this),
            winner,
            auction.tokenId,
            auction.tokenAmount,
            ""
        );
        auctionIds.remove(auctionId);
        emit AuctionClaimed(winner, auctionId);
    }

    /**
     * @dev Cancel auction and refund bidders
     *
     * Params:
     * auctionId: auction ID
     */
    function cancelAuction(uint256 auctionId)
        external
        nonReentrant()
        sellerOrAdmin(auctions[auctionId].seller)
    {
        require(auctionIds.contains(auctionId), "Auction does not exist");
        Auction memory auction = auctions[auctionId];

        require(
            block.timestamp <= auction.endTime,
            "Cannot cancel auction after it has ended"
        );

        IERC1155(auction.tokenAddress).safeTransferFrom(
            address(this),
            auction.seller,
            auction.tokenId,
            auction.tokenAmount,
            ""
        );

        if (auction.isStarsAuction) {
            stars.safeTransfer(
                auction.highestBid.bidder,
                auction.highestBid.amount
            );
        } else {
            (bool success, ) =
                auction.highestBid.bidder.call{
                    value: auction.highestBid.amount
                }("");
            require(success, "Payment failure");
        }

        auctionIds.remove(auctionId);
        emit AuctionCancelled(auctionId);
    }

    //Generate ID for next listing
    function generateListingId() internal returns (uint256) {
        return nextListingId++;
    }

    //Generate ID for next auction
    function generateAuctionId() internal returns (uint256) {
        return nextAuctionId++;
    }

    //Withdraw ETH to treasury wallet
    function withdrawETH() external onlyAdmin {
        (bool success, ) = treasuryWallet.call{value: adminEth}("");
        require(success, "Payment failure");
        adminEth = 0;
    }

    //Withdraw Stars to treasury wallet
    function withdrawStars() external onlyAdmin {
        stars.safeTransfer(treasuryWallet, adminStars);
        adminStars = 0;
    }

    //Add to list of valid Mogul NFTs
    function addMogulNFTAddress(address _mogulNFTAddress) external onlyAdmin {
        mogulNFTs.add(_mogulNFTAddress);
    }

    //Remove from list of valid Mogul NFTs
    function removeMogulNFTAddress(address _mogulNFTAddress)
        external
        onlyAdmin
    {
        mogulNFTs.remove(_mogulNFTAddress);
    }

    //Set fee (applies to all listings and auctions)
    function setFee(uint256 _feeBasisPoint) external onlyAdmin {
        require(
            _feeBasisPoint + highestCommissionBasisPoint < 10000,
            "Fee plus commission must be less than 100%"
        );
        feeBasisPoint = _feeBasisPoint;
    }

    //Set commission info for one token
    function setCommission(
        address NFTAddress,
        uint256 tokenId,
        address payable artistAddress,
        uint256 commissionBasisPoint
    ) external onlyAdmin {
        if (commissionBasisPoint > highestCommissionBasisPoint) {
            require(
                commissionBasisPoint + feeBasisPoint < 10000,
                "Fee plus commission must be less than 100%"
            );

            highestCommissionBasisPoint = commissionBasisPoint;
        }

        commissions[NFTAddress][tokenId] = TokenCommissionInfo(
            artistAddress,
            commissionBasisPoint
        );

        emit TokenCommissionSingleAdded(
            NFTAddress,
            tokenId,
            artistAddress,
            commissionBasisPoint
        );
    }

    //Set commission info for multiple tokens
    function setCommissionBulk(
        address NFTAddress,
        uint256[] memory tokenIds,
        address payable[] memory artistAddresses,
        uint256[] memory commissionBasisPoints
    ) external onlyAdmin {
        require(
            tokenIds.length == artistAddresses.length &&
                artistAddresses.length == commissionBasisPoints.length,
            "Invalid input lengths"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (commissionBasisPoints[i] > highestCommissionBasisPoint) {
                require(
                    commissionBasisPoints[i] + feeBasisPoint < 10000,
                    "Fee plus commission must be less than 100%"
                );

                highestCommissionBasisPoint = commissionBasisPoints[i];
            }
            commissions[NFTAddress][tokenIds[i]] = TokenCommissionInfo(
                artistAddresses[i],
                commissionBasisPoints[i]
            );
        }

        emit TokenCommissionBulkAdded(
            NFTAddress,
            tokenIds,
            artistAddresses,
            commissionBasisPoints
        );
    }

    //Set whether or not creating new Stars listings and Auctions are allowed
    function setStarsAllowed(bool _starsAllowed) external onlyAdmin {
        starsAllowed = _starsAllowed;
    }
}
