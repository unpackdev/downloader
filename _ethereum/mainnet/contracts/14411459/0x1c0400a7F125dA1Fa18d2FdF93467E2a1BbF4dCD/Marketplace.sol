// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./IERC20Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

contract Marketplace is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    /**
     * Variables
     */

    /// @notice Types of offer
    enum Types {
        regular,
        auction,
        offer
    }

    /// @notice Bid object
    struct Bid {
        address payable buyer;
        uint256 amount;
        bool isWinner;
        bool isChargedBack;
    }

    /// @notice Lot object
    struct Lot {
        address nft;
        address payable seller;
        uint256 tokenId;
        Types offerType;
        uint256 price;
        uint256 stopPrice;
        uint256 auctionStart;
        uint256 auctionEnd;
        bool isSold;
        bool isCanceled;
    }

    /// @notice Royalty object
    struct Royalty {
        uint256 percent;
        address receiver;
    }

    /// @dev This multiplier allows us to use the fractional part for the commission
    uint256 private constant FEES_MULTIPLIER = 10000;

    /// @notice Marketplace fee
    /// @dev 1 == 0.01%
    uint256 public serviceFee;

    /// @notice Maximal user royalty percent
    uint256 public maxRoyaltyPercent;

    /// @notice Address that will receive marketplace fees
    address payable public feesCollector;

    /// @notice ARA ERC20 token address
    address public ara;

    /// @notice RAD Pandas NFT address
    address public rad;

    /// @notice Users who are not allowed to the marketplace
    mapping(address => bool) public banList;

    /// @dev All lots IDs of the seller
    mapping(address => uint256[]) private lotsOfSeller;

    /// @notice All bids of lot
    mapping(uint256 => Bid[]) public bidsOfLot;

    /// @notice Sellers royalties
    mapping(address => mapping(uint256 => Royalty)) public royalties;

    /// @notice Array of lots
    Lot[] public lots;

    /**
     * Events
     */

    /// @notice When service fee changed
    event ServiceFeeChanged(uint256 newFee);

    /// @notice When maximal royalty percent changed
    event MaxRoyaltyChanged(uint256 newMaxRoyaltyPercent);

    /// @notice When user gets ban or unban status
    event UserBanStatusChanged(address indexed user, bool isBanned);

    /// @notice When address of ARA token changed
    event ARAAddressChanged(address indexed oldAddress, address indexed newAddress);

    /// @notice When address of RAD Pandas token changed
    event RADAddressChanged(address indexed oldAddress, address indexed newAddress);

    /// @notice When new regular lot created
    event RegularLotCreated(uint256 indexed lotId, address indexed seller);

    /// @notice When new auction lot created
    event AuctionLotCreated(uint256 indexed lotId, address indexed seller);

    /// @notice When new offer lot created
    event OfferLotCreated(uint256 indexed lotId, address indexed seller);

    /// @notice When lot removed
    event TokenRemovedFromSale(uint256 indexed lotId, bool indexed removedBySeller);

    /// @notice When lot sold
    event Sold(uint256 indexed lotId, address indexed buyer, uint256 price, uint256 fee, uint256 royalty);

    /// @notice When something was wrong with transaction
    event FailedTx(uint256 indexed lotId, uint256 bidId, address indexed recipient, uint256 amount);

    /// @notice When royalty set
    event RoyaltySet(address indexed nft, uint256 indexed tokenId, address receiver, uint256 percent);

    /// @notice When price offer created
    event NewOffer(address indexed buyer, uint256 price, uint256 indexed lotId);

    /// @notice When offer accepted by the seller
    event OfferAccepted(uint256 indexed lotId);

    /**
     * Modifiers
     */

    /**
     * @notice Checks that the user is not banned
     */
    modifier notBanned() {
        require(!banList[msg.sender], "you are banned");
        _;
    }

    /**
     * @notice Checks that the lot has not been sold or canceled
     * @param lotId - ID of the lot
     */
    modifier lotIsActive(uint256 lotId) {
        Lot memory lot = lots[lotId];
        require(!lot.isSold, "lot already sold");
        require(!lot.isCanceled, "lot canceled");
        _;
    }

    /**
     * Getters
     */

    /**
     * @notice Get filtered lots
     * @param from - Minimal lotId
     * @param to - Get to lot Id. 0 ar any value greater than lots.length will set "to" to lots.length
     * @param getActive - Is get active lots?
     * @param getSold - Is get sold lots?
     * @param getCanceled - Is get canceled lots?
     * @return _filteredLots - Array of filtered lots
     */
    function getLots(
        uint256 from,
        uint256 to,
        bool getActive,
        bool getSold,
        bool getCanceled
    ) external view returns (Lot[] memory _filteredLots) {
        require(from < lots.length, "value is bigger than lots count");
        if (to == 0 || to >= lots.length) to = lots.length - 1;
        Lot[] memory _tempLots = new Lot[](lots.length);
        uint256 _count = 0;
        for (uint256 i = from; i <= to; i++) {
            if (
                (getActive && (!lots[i].isSold && !lots[i].isCanceled)) ||
                (getSold && lots[i].isSold) ||
                (getCanceled && lots[i].isCanceled)
            ) {
                _tempLots[_count] = lots[i];
                _count++;
            }
        }
        _filteredLots = new Lot[](_count);
        for (uint256 i = 0; i < _count; i++) {
            _filteredLots[i] = _tempLots[i];
        }
    }

    /**
     * @notice Get all lots of the seller
     * @param seller - Address of seller
     * @return array of lot IDs
     */
    function getLotsOfSeller(address seller) external view returns (uint256[] memory) {
        return lotsOfSeller[seller];
    }

    /**
     * @notice Get all bids of the lot
     * @param lotId - ID of lot
     * @return array of lot IDs
     */
    function getBidsOfLot(uint256 lotId) external view returns (Bid[] memory) {
        return bidsOfLot[lotId];
    }

    /**
     * @notice Get lot by ERC721 address and token ID
     * @param nft - Address of ERC721 token
     * @param tokenId - ID of the token
     * @return _isFound - Is found or not
     * @return _lotId - ID of the lot
     */
    function getLotId(address nft, uint256 tokenId) external view returns (bool _isFound, uint256 _lotId) {
        require(nft != address(0), "zero_addr");
        _isFound = false;
        _lotId = 0;
        for (uint256 i; i < lots.length; i++) {
            Lot memory _lot = lots[i];
            if (_lot.nft == nft && _lot.tokenId == tokenId && !_lot.isCanceled && !_lot.isSold) {
                _isFound = true;
                _lotId = i;
                break;
            }
        }
    }

    /**
     * @notice Get bids of the user by lot Id
     * @param bidder - User's address
     * @param lotId - ID of lot
     * @return _bid - Return bid
     */
    function getBidsOf(address bidder, uint256 lotId) external view returns (Bid memory _bid) {
        for (uint256 i = 0; i < bidsOfLot[lotId].length; i++) {
            _bid = bidsOfLot[lotId][i];
            if (_bid.buyer == bidder && !_bid.isChargedBack) {
                return _bid;
            }
        }
        revert("bid not found");
    }

    /**
     * Setters
     */

    /**
     * @notice Change marketplace fee
     * @param newServiceFee - New fee amount
     */
    function setServiceFee(uint256 newServiceFee) external onlyOwner {
        require(serviceFee != newServiceFee, "similar amount");
        serviceFee = newServiceFee;
        emit ServiceFeeChanged(newServiceFee);
    }

    /**
     * @notice Change user's ban status
     * @param user - Address of account
     * @param isBanned - Status of account
     */
    function setBanStatus(address user, bool isBanned) external onlyOwner {
        require(banList[user] != isBanned, "address already have this status");
        banList[user] = isBanned;
        emit UserBanStatusChanged(user, isBanned);
    }

    /**
     * @notice Change ARA token address
     * @param _ara - New address of the ARA ERC20 token
     */
    function setARAAddress(address _ara) external onlyOwner {
        require(_ara != address(0), "zero address");
        require(_ara != ara, "same address");
        address _oldARA = ara;
        ara = _ara;
        emit ARAAddressChanged(_oldARA, ara);
    }

    /**
     * @notice Change RAD Pandas token address
     * @param _rad - New address of the RAD NFT
     */
    function setRADAddress(address _rad) external onlyOwner {
        require(_rad != address(0), "zero address");
        require(_rad != rad, "same address");
        address _oldRAD = rad;
        rad = _rad;
        emit RADAddressChanged(_oldRAD, rad);
    }

    /**
     * @notice Set maximal royalty percent
     * @param newMaxRoyaltyPercent - New maximal royalty percent
     */
    function setMaxRoyalty(uint256 newMaxRoyaltyPercent) external onlyOwner {
        require(maxRoyaltyPercent != newMaxRoyaltyPercent, "similar amount");
        maxRoyaltyPercent = newMaxRoyaltyPercent;
        emit MaxRoyaltyChanged(newMaxRoyaltyPercent);
    }

    /**
     * @notice Set royalty
     * @dev Can be set only ones
     * @param nftToken - Address of NFT token
     * @param tokenId - ID of NFT token
     * @param royaltyPercent - Royalty (1% == 100)
     */
    function setRoyalty(
        address nftToken,
        uint256 tokenId,
        uint256 royaltyPercent
    ) external {
        require(royaltyPercent <= maxRoyaltyPercent, "% is too big");
        Royalty storage _royalty = royalties[nftToken][tokenId];
        require(_royalty.percent == 0, "Royalty % already set");
        require(_royalty.receiver == address(0), "Royalty address already set");
        address _tokenOwner = IERC721Upgradeable(nftToken).ownerOf(tokenId);
        require(msg.sender == _tokenOwner, "not owner");
        _royalty.percent = royaltyPercent;
        _royalty.receiver = msg.sender;
        emit RoyaltySet(nftToken, tokenId, msg.sender, royaltyPercent);
    }

    /**
     * Marketplace logic
     */

    /**
     * @notice Regular offer (not auction)
     * @param nft - Address of NFT contract
     * @param tokenId - ID of token to sale
     * @param price - Token price
     * @return _lotId - Lot ID
     */
    function makeRegularOffer(
        address nft,
        uint256 tokenId,
        uint256 price
    ) external notBanned returns (uint256 _lotId) {
        require(nft != address(0), "zero address for NFT");
        require(price > 0, "price should be greater than 0");
        IERC721Upgradeable(nft).safeTransferFrom(msg.sender, address(this), tokenId);
        Lot memory newLot = Lot(nft, payable(msg.sender), tokenId, Types.regular, price, 0, 0, 0, false, false);
        lots.push(newLot);
        _lotId = lots.length - 1;
        lotsOfSeller[msg.sender].push(_lotId);
        emit RegularLotCreated(_lotId, msg.sender);
    }

    /**
     * @notice Regular offer (not auction)
     * @param nft - Address of NFT contract
     * @param tokenId - ID of token to sale
     * @param price - Token price
     * @param stopPrice - Price to stop auction and sale immediately
     * @param auctionStart - Auction starts at
     * @param auctionEnd - Auction finish at
     * @return _lotId - Lot ID
     */
    function makeAuctionOffer(
        address nft,
        uint256 tokenId,
        uint256 price,
        uint256 stopPrice,
        uint256 auctionStart,
        uint256 auctionEnd
    ) external notBanned returns (uint256 _lotId) {
        require(nft != address(0), "zero address");
        require(auctionStart > 0, "auction start time should be greater than 0");
        require(auctionEnd > auctionStart, "auction end time should be greater than auction start time");
        require(price > 0, "price should be greater than 0");
        if (stopPrice > 0) {
            require(stopPrice > price, "stop price should be greater than price");
        }
        IERC721Upgradeable(nft).safeTransferFrom(msg.sender, address(this), tokenId);
        Lot memory newLot = Lot(
            nft,
            payable(msg.sender),
            tokenId,
            Types.auction,
            price,
            stopPrice,
            auctionStart,
            auctionEnd,
            false,
            false
        );
        lots.push(newLot);
        _lotId = lots.length - 1;
        lotsOfSeller[msg.sender].push(_lotId);
        emit AuctionLotCreated(_lotId, msg.sender);
    }

    /**
     * @notice Add token to receive price offers
     * @param nft - Address of NFT contract
     * @param tokenId - ID of token to sale
     * @return _lotId - Lot ID
     */
    function addTokenForOffers(address nft, uint256 tokenId) external notBanned returns (uint256 _lotId) {
        require(nft != address(0), "zero address for NFT");
        IERC721Upgradeable(nft).safeTransferFrom(msg.sender, address(this), tokenId);
        Lot memory newLot = Lot(nft, payable(msg.sender), tokenId, Types.offer, 0, 0, 0, 0, false, false);
        lots.push(newLot);
        _lotId = lots.length - 1;
        lotsOfSeller[msg.sender].push(_lotId);
        emit RegularLotCreated(_lotId, msg.sender);
    }

    /**
     * @notice Remove lot from sale and return users funds
     * @dev Only lot owner or contract owner can do this
     * @param lotId - ID of the lot
     */
    function removeLot(uint256 lotId) external lotIsActive(lotId) nonReentrant {
        Lot storage lot = lots[lotId];
        require(msg.sender == lot.seller || msg.sender == owner(), "only owner or seller can remove");
        lot.isCanceled = true;
        if (lot.offerType != Types.regular) {
            // send funds to bidders
            Bid[] storage bids = bidsOfLot[lotId];
            for (uint256 i = 0; i < bids.length; i++) {
                Bid storage _bid = bids[i];
                if (!_bid.isChargedBack && !_bid.isWinner) {
                    _bid.isChargedBack = true;
                    (bool sent, ) = _bid.buyer.call{value: _bid.amount}("");
                    require(sent, "something went wrong");
                }
            }
        }
        // send NFT back to the seller
        IERC721Upgradeable(lot.nft).safeTransferFrom(address(this), lot.seller, lot.tokenId);
        emit TokenRemovedFromSale(lotId, msg.sender == lot.seller);
    }

    /**
     * @notice Update price for a regular offer
     * @param lotId - ID of the lot
     * @param newPrice - New price of the lot
     */
    function changeRegularOfferPrice(uint256 lotId, uint256 newPrice) external lotIsActive(lotId) {
        Lot storage _lot = lots[lotId];
        require(msg.sender == _lot.seller, "not seller");
        require(_lot.offerType == Types.regular, "only regular offer");
        require(_lot.price != newPrice, "same");
        _lot.price = newPrice;
    }

    /**
     * @notice Make offer to lot
     * @param lotId - ID of the lot
     */
    function makeOffer(uint256 lotId) external payable notBanned lotIsActive(lotId) nonReentrant {
        Lot storage lot = lots[lotId];
        require(lot.offerType == Types.offer, "only offer lot type");
        Bid[] storage _bids = bidsOfLot[lotId];
        if (_bids.length > 0) {
            (bool _hasActiveBid, uint256 _activeBidId) = _getLastActiveBid(lotId);
            if (_hasActiveBid) {
                require(msg.value > _bids[_activeBidId].amount);
                (bool _isOk, uint256 _id) = _getMyLastOfferBid(lotId);
                if (_isOk) {
                    Bid storage _lastBid = _bids[_id];
                    _lastBid.isChargedBack = true;
                    (bool isTransfered, ) = _lastBid.buyer.call{value: _lastBid.amount}("");
                    require(isTransfered, "payment error");
                }
            }
        }
        Bid memory _newBid = Bid(payable(msg.sender), msg.value, false, false);
        (bool isOk, ) = payable(address(this)).call{value: msg.value}("");
        require(isOk, "payment error");
        _bids.push(_newBid);
        emit NewOffer(msg.sender, msg.value, lotId);
    }

    /**
     * @notice Make offer to lot
     * @param lotId - ID of the lot
     */
    function acceptOffer(uint256 lotId) external payable notBanned lotIsActive(lotId) nonReentrant {
        Lot storage lot = lots[lotId];
        require(lot.seller == msg.sender, "seller only");
        require(lot.offerType == Types.offer, "only offer lot type");
        Bid[] storage _bids = bidsOfLot[lotId];
        require(_bids.length > 0, "no bids");
        (bool _hasActiveBid, uint256 _activeBidId) = _getLastActiveBid(lotId);
        require(_hasActiveBid, "no active bids");
        Bid storage _winner = _bids[_activeBidId];
        _winner.isWinner = true;
        _buy(lot, _winner.amount, lotId);
        emit OfferAccepted(lotId);
    }

    /**
     * @notice Buy regular lot (not auction)
     * @param lotId - ID of the lot
     */
    function buy(uint256 lotId) external payable notBanned lotIsActive(lotId) nonReentrant {
        Lot storage lot = lots[lotId];
        require(lot.offerType == Types.regular, "only regular lot type");
        require(msg.value == lot.price, "wrong ether amount");
        _buy(lot, lot.price, lotId);
    }

    /**
     * @notice Make auction bid
     * @param lotId - ID of the lot
     */
    function bid(uint256 lotId) external payable notBanned lotIsActive(lotId) nonReentrant {
        Lot storage lot = lots[lotId];
        require(lot.offerType == Types.auction, "only auction lot type");
        require(lot.auctionStart <= block.timestamp, "auction is not started yet");
        require(lot.auctionEnd >= block.timestamp, "auction already finished");
        Bid[] storage bids = bidsOfLot[lotId];
        uint256 bidAmount = msg.value;
        for (uint256 i = 0; i < bids.length; i++) {
            if (bids[i].buyer == msg.sender && !bids[i].isChargedBack) {
                bidAmount += bids[i].amount;
            }
        }
        if (lot.stopPrice != 0) {
            require(bidAmount <= lot.stopPrice, "amount should be less or equal to stop price");
        }
        require(bidAmount >= lot.price, "amount should be great or equal to lot price");
        if (bids.length > 0) {
            require(bids[bids.length - 1].amount < bidAmount, "bid should be greater than last");
        }
        // Pay
        (bool fundsInMarketplace, ) = payable(address(this)).call{value: msg.value}("");
        require(fundsInMarketplace, "payment error (bidder)");
        Bid memory newBid = Bid(payable(msg.sender), bidAmount, false, false);
        // Do not send funds to previous bids, because this amount in last bid
        for (uint256 i = 0; i < bids.length; i++) {
            if (bids[i].buyer == msg.sender && !bids[i].isChargedBack) {
                bids[i].isChargedBack = true;
            }
        }
        bids.push(newBid);
        // finalize when target price reached
        if (lot.stopPrice != 0 && bidAmount == lot.stopPrice) {
            lot.auctionEnd = block.timestamp - 1;
            _finalize(lotId);
        }
    }

    /**
     * @notice Finalize auction (external function)
     * @param lotId - ID of the lot
     */
    function finalize(uint256 lotId) external notBanned lotIsActive(lotId) nonReentrant {
        _finalize(lotId);
    }

    /**
     * Private functions
     */

    /**
     * @dev Get last offer bid of msg.sender
     * @param _lotId - ID of the lot
     * @return _isOk - Bid found
     * @return _bidId - Id of the lot bid
     */
    function _getMyLastOfferBid(uint256 _lotId) internal view returns (bool _isOk, uint256 _bidId) {
        Bid[] memory _bids = bidsOfLot[_lotId];
        if (_bids.length > 0) {
            for (uint256 _i = _bids.length - 1; _i >= 0; _i--) {
                if (_bids[_i].buyer == msg.sender && !_bids[_i].isChargedBack) {
                    _isOk = true;
                    _bidId = _i;
                    break;
                }
            }
        }
    }

    /**
     * @dev Get last offer bid
     * @param _lotId - ID of the lot
     * @return _isOk - Bid found
     * @return _bidId - Id of the lot bid
     */
    function _getLastActiveBid(uint256 _lotId) internal view returns (bool _isOk, uint256 _bidId) {
        Bid[] memory _bids = bidsOfLot[_lotId];
        if (_bids.length > 0) {
            for (uint256 _i = _bids.length - 1; _i >= 0; _i--) {
                if (!_bids[_i].isChargedBack) {
                    _isOk = true;
                    _bidId = _i;
                    break;
                }
            }
        }
    }

    /**
     * @dev Send funds and token
     * @param lot - Lot to buy
     * @param price - Lot price
     * @param lotId - ID of the lot
     */
    function _buy(
        Lot storage lot,
        uint256 price,
        uint256 lotId
    ) internal {
        uint256 _fee = (price * serviceFee) / FEES_MULTIPLIER;
        uint256 _royaltyPercent = 0;
        bool _payRoyalty = IERC20Upgradeable(ara).balanceOf(lot.seller) < 50000 ether;
        if (_payRoyalty) {
            _payRoyalty = IERC721Upgradeable(rad).balanceOf(lot.seller) < 1;
        }
        if (_payRoyalty) {
            Royalty memory _royalty = royalties[lot.nft][lot.tokenId];
            if (_royalty.percent > 0) {
                _royaltyPercent = (price * _royalty.percent) / FEES_MULTIPLIER;
                (bool payedRoyalty, ) = payable(_royalty.receiver).call{value: _royaltyPercent}("");
                require(payedRoyalty, "payment error (royalty)");
            }
        }
        (bool payedToSeller, ) = lot.seller.call{value: price - _fee - _royaltyPercent}("");
        require(payedToSeller, "payment error (seller)");
        (bool payedToFeesCollector, ) = feesCollector.call{value: _fee}("");
        require(payedToFeesCollector, "payment error (fees collector)");
        lot.isSold = true;
        IERC721Upgradeable(lot.nft).safeTransferFrom(address(this), msg.sender, lot.tokenId);
        emit Sold(lotId, msg.sender, price, _fee, _royaltyPercent);
    }

    /**
     * @dev Finalize auction (internal function)
     * @param lotId - ID of the lot
     */
    function _finalize(uint256 lotId) internal {
        Lot storage lot = lots[lotId];
        Bid[] storage bids = bidsOfLot[lotId];
        require(bids.length > 0, "no bids");
        require(lot.auctionEnd < block.timestamp, "auction is not finished yet");
        uint256 winnerId;
        if (bids.length == 1) {
            winnerId = 0;
        } else {
            winnerId = bids.length - 1;
            for (uint256 i = 0; i < bids.length - 1; i++) {
                Bid storage _bid = bids[i];
                if (!_bid.isChargedBack) {
                    _bid.isChargedBack = true;
                    (bool success, ) = _bid.buyer.call{value: _bid.amount}("");
                    if (!success) {
                        emit FailedTx(lotId, i, _bid.buyer, _bid.amount);
                    }
                }
            }
        }
        bids[winnerId].isWinner = true;
        _buy(lot, bids[winnerId].amount, lotId);
    }

    /**
     * Other
     */

    /// @notice Acts like constructor() for upgradeable contracts
    function initialize(address _ara, address _rad) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        feesCollector = payable(msg.sender);
        serviceFee = 0;
        maxRoyaltyPercent = 1000; // 10%
        ara = _ara;
        rad = _rad;
    }

    /// @notice To make ERC721 safeTransferFrom works
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    /// @notice Allow this contract to receive ether
    receive() external payable {}
}
