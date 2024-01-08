// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

import "./ITux.sol";
import "./ITuxERC20.sol";
import "./IAuctions.sol";

import "./UintSet.sol";
import "./AddressSet.sol";
import "./OrderedSet.sol";
import "./RankedSet.sol";
import "./RankedAddressSet.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";


contract Auctions is
    IAuctions
{
    using UintSet for UintSet.Set;
    using AddressSet for AddressSet.Set;
    using OrderedSet for OrderedSet.Set;
    using RankedSet for RankedSet.Set;
    using RankedAddressSet for RankedAddressSet.Set;

    uint256 private _lastBidId;
    uint256 private _lastOfferId;
    uint256 private _lastHouseId;
    uint256 private _lastAuctionId;

    // TuxERC20 contract address
    address public tuxERC20;

    // Minimum amount of time left in seconds to an auction after a new bid is placed
    uint256 constant public timeBuffer = 900;  // 15 minutes -> 900 seconds

    // Minimum percentage difference between the last bid and the current bid
    uint16 constant public minimumIncrementPercentage = 500;  // 5%

    // Mapping from house name to house ID
    mapping(string => uint256) public houseIDs;

    // Mapping from keccak256(contract, token) to currently running auction ID
    mapping(bytes32 => uint256) public tokenAuction;

    // Mapping of token contracts
    mapping(address => IAuctions.TokenContract) public contracts;

    // Mapping of auctions
    mapping(uint256 => IAuctions.Auction) public auctions;

    // Mapping of houses
    mapping(uint256 => IAuctions.House) public houses;

    // Mapping of bids
    mapping(uint256 => IAuctions.Bid) public bids;

    // Mapping of offers
    mapping(uint256 => IAuctions.Offer) public offers;

    // Mapping of accounts
    mapping(address => IAuctions.Account) public accounts;

    // Mapping from creator to stats
    mapping(address => IAuctions.CreatorStats) public creatorStats;

    // Mapping from collector to stats
    mapping(address => IAuctions.CollectorStats) public collectorStats;

    // Mapping from creator to token contracts
    mapping(address => AddressSet.Set) private _collections;

    // Mapping from house ID to token IDs requiring approval
    mapping(uint256 => UintSet.Set) private _houseQueue;

    // Mapping from auction ID to bids
    mapping(uint256 => UintSet.Set) private _auctionBids;

    // Mapping from house ID to active auction IDs
    mapping(uint256 => OrderedSet.Set) private _houseAuctions;

    // Mapping from curator to enumerable house IDs
    mapping(address => UintSet.Set) private _curatorHouses;

    // Mapping from creator to enumerable house IDs
    mapping(address => UintSet.Set) private _creatorHouses;

    // Mapping from house id to enumerable creators
    mapping(uint256 => AddressSet.Set) private _houseCreators;

    // Mapping from seller to active auction IDs
    mapping(address => UintSet.Set) private _sellerAuctions;

    // Mapping from bidder to active auction IDs
    mapping(address => UintSet.Set) private _bidderAuctions;

    // Mapping from keccak256(contract, token) to previous auction IDs
    mapping(bytes32 => UintSet.Set) private _previousTokenAuctions;

    // Mapping from keccak256(contract, token) to offer IDs
    mapping(bytes32 => UintSet.Set) private _tokenOffers;

    // RankedSet of house IDs
    RankedSet.Set private _rankedHouses;

    // RankedAddressSet of creators
    RankedAddressSet.Set private _rankedCreators;

    // RankedAddressSet of collectors
    RankedAddressSet.Set private _rankedCollectors;

    // OrderedSet of active token contracts
    RankedAddressSet.Set private _rankedContracts;

    // OrderedSet of active houses
    OrderedSet.Set private _activeHouses;

    // OrderedSet of active auction IDs without a house ID
    OrderedSet.Set private _activeAuctions;


    bytes4 constant interfaceId = 0x80ac58cd; // ERC721 interfaceId
    bytes4 constant interfaceIdMetadata = 0x5b5e139f; // Metadata extension
    bytes4 constant interfaceIdEnumerable = 0x780e9d63; // Enumerable extension


    modifier auctionExists(uint256 auctionId) {
        require(
            auctions[auctionId].tokenOwner != address(0),
            "Does not exist");
        _;
    }

    modifier onlyHouseCurator(uint256 houseId) {
        require(
            msg.sender == houses[houseId].curator,
            "Not house curator");
        _;
    }


    /*
     * Constructor
     */
    constructor(
        address tuxERC20_
    ) {
        tuxERC20 = tuxERC20_;
    }

    function totalHouses() public view override returns (uint256) {
        return _lastHouseId;
    }

    function totalAuctions() public view override returns (uint256) {
        return _lastAuctionId;
    }

    function totalContracts() public view override returns (uint256) {
        return _rankedContracts.length();
    }

    function totalCreators() public view override returns (uint256) {
        return _rankedCreators.length();
    }

    function totalCollectors() public view override returns (uint256) {
        return _rankedCollectors.length();
    }

    function totalActiveHouses() public view override returns (uint256) {
        return _activeHouses.length();
    }

    function totalActiveAuctions() public view override returns (uint256) {
        return _activeAuctions.length();
    }

    function totalActiveHouseAuctions(uint256 houseId) public view override returns (uint256) {
        return _houseAuctions[houseId].length();
    }

    function getActiveHouses(uint256 from, uint256 n) public view override returns (uint256[] memory) {
        return _activeHouses.valuesFromN(from, n);
    }

    function getRankedHouses(uint256 from, uint256 n) public view override returns (uint256[] memory) {
        return _rankedHouses.valuesFromN(from, n);
    }

    function getRankedCreators(address from, uint256 n) public view override returns (address[] memory) {
        return _rankedCreators.valuesFromN(from, n);
    }

    function getRankedCollectors(address from, uint256 n) public view override returns (address[] memory) {
        return _rankedCollectors.valuesFromN(from, n);
    }

    function getRankedContracts(address from, uint256 n) public view override returns (address[] memory) {
        return _rankedContracts.valuesFromN(from, n);
    }

    function getCollections(address creator) external view override returns (address[] memory) {
        return _collections[creator].values();
    }

    function getAuctions(uint256 from, uint256 n) public view override returns (uint256[] memory) {
        return _activeAuctions.valuesFromN(from, n);
    }

    function getHouseAuctions(uint256 houseId, uint256 from, uint256 n) public view override returns (uint256[] memory) {
        return _houseAuctions[houseId].valuesFromN(from, n);
    }

    function getHouseQueue(uint256 houseId) public view override returns (uint256[] memory) {
        return _houseQueue[houseId].values();
    }

    function getAuctionBids(uint256 auctionId) public view override returns (uint256[] memory) {
        return _auctionBids[auctionId].values();
    }

    function getCuratorHouses(address curator) public view override returns (uint256[] memory) {
        return _curatorHouses[curator].values();
    }

    function getCreatorHouses(address creator) public view override returns (uint256[] memory) {
        return _creatorHouses[creator].values();
    }

    function getHouseCreators(uint256 houseId) public view override returns (address[] memory) {
        return _houseCreators[houseId].values();
    }

    function getSellerAuctions(address seller) public view override returns (uint256[] memory) {
        return _sellerAuctions[seller].values();
    }

    function getBidderAuctions(address bidder) public view override returns (uint256[] memory) {
        return _bidderAuctions[bidder].values();
    }

    function getPreviousAuctions(bytes32 tokenHash) public view override returns (uint256[] memory) {
        return _previousTokenAuctions[tokenHash].values();
    }

    function getTokenOffers(bytes32 tokenHash) public view override returns (uint256[] memory) {
        return _tokenOffers[tokenHash].values();
    }


    function createHouse(
        string  memory name,
        address curator,
        uint16  fee,
        bool    preApproved,
        string  memory metadata
    )
        public
        override
    {
        require(
            houseIDs[name] == 0,
            "Already exists");
        require(
            bytes(name).length > 0,
            "Name required");
        require(
            bytes(name).length <= 32,
            "Name too long");
        require(
            curator != address(0),
            "Address required");
        require(
            fee < 10000,
            "Fee too high");

        _lastHouseId += 1;
        uint256 houseId = _lastHouseId;

        houses[houseId].name = name;
        houses[houseId].curator = payable(curator);
        houses[houseId].fee = fee;
        houses[houseId].preApproved = preApproved;
        houses[houseId].metadata = metadata;

        _curatorHouses[curator].add(houseId);
        _rankedHouses.add(houseId);
        houseIDs[name] = houseId;

        ITuxERC20(tuxERC20).updateFeatured();
        ITuxERC20(tuxERC20).mint(msg.sender, 5 * 10**18);

        emit HouseCreated(
            houseId
        );
    }

    function addCreator(
        uint256 houseId,
        address creator
    )
        public
        override
        onlyHouseCurator(houseId)
    {
        require(
            _houseCreators[houseId].contains(creator) == false,
            "Already added");

        _houseCreators[houseId].add(creator);
        _creatorHouses[creator].add(houseId);

        ITuxERC20(tuxERC20).mint(msg.sender, 1 * 10**18);

        emit CreatorAdded(
            houseId,
            creator
        );
    }

    function removeCreator(
        uint256 houseId,
        address creator
    )
        public
        override
        onlyHouseCurator(houseId)
    {
        require(
            _houseCreators[houseId].contains(creator) == true,
            "Already removed");

        _houseCreators[houseId].remove(creator);
        _creatorHouses[creator].remove(houseId);

        emit CreatorRemoved(
            houseId,
            creator
        );
    }

    function updateFee(
        uint256 houseId,
        uint16  fee
    )
        public
        override
        onlyHouseCurator(houseId)
    {
        require(
            fee < 10000,
            "Fee too high");

        houses[houseId].fee = fee;

        emit FeeUpdated(
            houseId,
            fee
        );
    }

    function updateMetadata(
        uint256 houseId,
        string memory metadata
    )
        public
        override
        onlyHouseCurator(houseId)
    {
        houses[houseId].metadata = metadata;

        emit MetadataUpdated(
            houseId,
            metadata
        );
    }

    function updateName(
        string  memory name
    )
        public
        override
    {
        accounts[msg.sender].name = name;

        emit AccountUpdated(
            msg.sender
        );
    }

    function updateBio(
        string  memory bioHash
    )
        public
        override
    {
        accounts[msg.sender].bioHash = bioHash;

        emit AccountUpdated(
            msg.sender
        );
    }

    function updatePicture(
        string  memory pictureHash
    )
        public
        override
    {
        accounts[msg.sender].pictureHash = pictureHash;

        emit AccountUpdated(
            msg.sender
        );
    }

    function createAuction(
        address tokenContract,
        uint256 tokenId,
        uint256 duration,
        uint256 reservePrice,
        uint256 houseId
    )
        public
        override
    {
        if (contracts[tokenContract].tokenContract == address(0)) {
            registerTokenContract(tokenContract);
        }

        address tokenOwner = IERC721(tokenContract).ownerOf(tokenId);
        require(
            msg.sender == tokenOwner ||
            msg.sender == IERC721(tokenContract).getApproved(tokenId),
            "Not owner or approved");

        uint16  fee = 0;
        bool    preApproved = true;
        address curator = address(0);

        if (houseId > 0) {
            curator = houses[houseId].curator;

            require(
                curator != address(0),
                "House does not exist");
            require(
                _houseCreators[houseId].contains(tokenOwner) || msg.sender == curator,
                "Not approved by curator");

            fee = houses[houseId].fee;
            preApproved = houses[houseId].preApproved;
            houses[houseId].activeAuctions += 1;
        }

        try ITux(tokenContract).tokenCreator(tokenId) returns (address creator) {
            if (!_rankedCreators.contains(creator)) {
                _rankedCreators.add(creator);
            }
        } catch {}

        _lastAuctionId += 1;
        uint256 auctionId = _lastAuctionId;

        tokenAuction[keccak256(abi.encode(tokenContract, tokenId))] = auctionId;

        _sellerAuctions[tokenOwner].add(auctionId);

        bool approved = (curator == address(0) || preApproved || curator == tokenOwner);

        if (houseId > 0) {
            if (approved == true) {
                _houseAuctions[houseId].add(auctionId);
                if (_activeHouses.head() != houseId) {
                    if (_activeHouses.contains(houseId)) {
                        _activeHouses.remove(houseId);
                    }
                    _activeHouses.add(houseId);
                }
            }
            else {
                _houseQueue[houseId].add(auctionId);
            }
        }
        else {
            _activeAuctions.add(auctionId);
        }

        auctions[auctionId] = Auction({
            tokenContract: tokenContract,
            tokenId: tokenId,
            tokenOwner: tokenOwner,
            duration: duration,
            reservePrice: reservePrice,
            houseId: houseId,
            fee: fee,
            approved: approved,
            firstBidTime: 0,
            amount: 0,
            bidder: payable(0),
            created: block.timestamp
        });

        IERC721(tokenContract).transferFrom(tokenOwner, address(this), tokenId);

        ITuxERC20(tuxERC20).updateFeatured();
        ITuxERC20(tuxERC20).mint(msg.sender, 10 * 10**18);

        emit AuctionCreated(
            auctionId
        );
    }

    function setAuctionApproval(uint256 auctionId, bool approved)
        public
        override
        auctionExists(auctionId)
    {
        IAuctions.Auction storage auction = auctions[auctionId];
        address curator = houses[auction.houseId].curator;

        require(
            curator == msg.sender,
            "Not auction curator");
        require(
            auction.firstBidTime == 0,
            "Already started");
        require(
            (approved == true && auction.approved == false) ||
            (approved == false && auction.approved == true),
            "Already in this state");

        auction.approved = approved;

        if (approved == true) {
            _houseAuctions[auction.houseId].add(auctionId);
            _houseQueue[auction.houseId].remove(auctionId);

            if (_activeHouses.head() != auction.houseId) {
                if (_activeHouses.contains(auction.houseId)) {
                    _activeHouses.remove(auction.houseId);
                }
                _activeHouses.add(auction.houseId);
            }
        }

        emit AuctionApprovalUpdated(
            auctionId,
            approved
        );
    }

    function setAuctionReservePrice(uint256 auctionId, uint256 reservePrice)
        public
        override
        auctionExists(auctionId)
    {
        IAuctions.Auction storage auction = auctions[auctionId];

        require(
            msg.sender == auction.tokenOwner,
            "Not token owner");
        require(
            auction.firstBidTime == 0,
            "Already started");

        auction.reservePrice = reservePrice;

        emit AuctionReservePriceUpdated(
            auctionId,
            reservePrice
        );
    }

    function createBid(uint256 auctionId)
        public
        payable
        override
        auctionExists(auctionId)
    {
        IAuctions.Auction storage auction = auctions[auctionId];

        require(
            auction.approved,
            "Not approved by curator");
        require(
            auction.firstBidTime == 0 ||
            block.timestamp < auction.firstBidTime + auction.duration,
            "Auction expired");
        require(
            msg.value >= auction.amount + (
                auction.amount * minimumIncrementPercentage / 10000),
            "Amount too low");
        require(
            msg.value >= auction.reservePrice,
            "Bid below reserve price");

        address payable lastBidder = auction.bidder;
        bool isFirstBid = true;
        if (lastBidder != payable(0)) {
            isFirstBid = false;
        }

        if (auction.firstBidTime == 0) {
            auction.firstBidTime = block.timestamp;
        } else if (isFirstBid == false) {
            _handleOutgoingBid(lastBidder, auction.amount);
        }

        auction.amount = msg.value;
        auction.bidder = payable(msg.sender);

        if (auction.duration > 0) {
            _lastBidId += 1;
            uint256 bidId = _lastBidId;

            bids[bidId] = Bid({
                timestamp: block.timestamp,
                bidder: msg.sender,
                value: msg.value
            });

            _auctionBids[auctionId].add(bidId);
            _bidderAuctions[msg.sender].add(auctionId);
        }

        contracts[auction.tokenContract].bids += 1;

        try ITux(auction.tokenContract).tokenCreator(auction.tokenId) returns (address creator) {
            if (creator == auction.tokenOwner) {
                creatorStats[auction.tokenOwner].bids += 1;
            }
        } catch {}

        if (collectorStats[msg.sender].bids == 0) {
            _rankedCollectors.add(msg.sender);
        }
        collectorStats[msg.sender].bids += 1;

        if (auction.houseId > 0) {
            houses[auction.houseId].bids += 1;
            /* _rankedHouses.rankScore(auction.houseId, houses[auction.houseId].bids); // This gets too expensive... */

            _houseAuctions[auction.houseId].remove(auctionId);
            _houseAuctions[auction.houseId].add(auctionId);
        }

        bool extended = false;
        if (auction.duration > 0) {
          uint256 timeRemaining = auction.firstBidTime + auction.duration - block.timestamp;
          if (timeRemaining < timeBuffer) {
              auction.duration += timeBuffer - timeRemaining;
              extended = true;
          }
        }

        ITuxERC20(tuxERC20).updateFeatured();
        ITuxERC20(tuxERC20).mint(msg.sender, 10 * 10**18);

        emit AuctionBid(
            auctionId,
            msg.sender,
            msg.value,
            isFirstBid,
            extended
        );

        if (extended) {
            emit AuctionDurationExtended(
                auctionId,
                auction.duration
            );
        }
    }

    function endAuction(uint256 auctionId)
        public
        override
        auctionExists(auctionId)
    {
        IAuctions.Auction storage auction = auctions[auctionId];

        require(
            uint256(auction.firstBidTime) != 0,
            "Not started");
        require(
            block.timestamp >=
            auction.firstBidTime + auction.duration,
            "Not ended");

        try IERC721(auction.tokenContract).safeTransferFrom(
            address(this), auction.bidder, auction.tokenId
        ) {} catch {
            _handleOutgoingBid(auction.bidder, auction.amount);
            _cancelAuction(auctionId);
            return;
        }

        uint256 houseId = auction.houseId;
        address curator = address(0);
        uint256 curatorFee = 0;
        uint256 tokenOwnerProfit = auction.amount;

        collectorStats[auction.bidder].bought += 1;
        collectorStats[auction.bidder].totalSpent += tokenOwnerProfit;
        contracts[auction.tokenContract].sales += 1;
        contracts[auction.tokenContract].total += tokenOwnerProfit;

        try ITux(auction.tokenContract).tokenCreator(auction.tokenId) returns (address creator) {
            if (creator == auction.tokenOwner) {
                creatorStats[creator].sales += 1;
                creatorStats[creator].total += tokenOwnerProfit;
            } else {
                collectorStats[auction.tokenOwner].sales += 1;
                collectorStats[auction.tokenOwner].totalSold += tokenOwnerProfit;
            }
        } catch {
            collectorStats[auction.tokenOwner].sales += 1;
            collectorStats[auction.tokenOwner].totalSold += tokenOwnerProfit;
        }

        if (houseId > 0) {
            curator = houses[houseId].curator;
            houses[houseId].sales += 1;
            houses[houseId].total += tokenOwnerProfit;
            if (houses[houseId].activeAuctions > 0) {
                houses[houseId].activeAuctions -= 1;
            }
            _houseAuctions[houseId].remove(auctionId);
        }
        else {
            _activeAuctions.remove(auctionId);
        }

        if (curator != address(0) && auction.fee > 0) {
            curatorFee = tokenOwnerProfit * auction.fee / 10000;
            tokenOwnerProfit = tokenOwnerProfit - curatorFee;
            _handleOutgoingBid(curator, curatorFee);
        }
        _handleOutgoingBid(auction.tokenOwner, tokenOwnerProfit);

        if (houseId > 0) {
            houses[houseId].feesTotal += curatorFee;
        }

        bytes32 auctionHash = keccak256(abi.encode(auction.tokenContract, auction.tokenId));
        _previousTokenAuctions[auctionHash].add(auctionId);
        delete tokenAuction[auctionHash];

        if (auction.duration > 0) {
            uint256 i = _auctionBids[auctionId].length();
            while (i > 0) {
                uint256 bidId = _auctionBids[auctionId].at(i - 1);
                _bidderAuctions[bids[bidId].bidder].remove(auctionId);
                i--;
            }
        }

        _sellerAuctions[auction.tokenOwner].remove(auctionId);

        ITuxERC20(tuxERC20).updateFeatured();
        ITuxERC20(tuxERC20).mint(msg.sender, 10 * 10**18);

        emit AuctionEnded(
            auctionId
        );
    }

    function buyAuction(uint256 auctionId)
        public
        payable
        override
    {
        createBid(auctionId);
        endAuction(auctionId);
    }

    function cancelAuction(uint256 auctionId)
        public
        override
        auctionExists(auctionId)
    {
        require(
            auctions[auctionId].tokenOwner == msg.sender,
            "Not auction owner");
        require(
            uint256(auctions[auctionId].firstBidTime) == 0,
            "Already started");

        _cancelAuction(auctionId);
    }

    function registerTokenContract(address tokenContract)
        public
        override
    {
        require(
            contracts[tokenContract].tokenContract == address(0),
            "Already registered");
        require(
            IERC165(tokenContract).supportsInterface(interfaceId),
            "Does not support ERC721");
        require(
            IERC165(tokenContract).supportsInterface(interfaceIdMetadata),
            "Does not support ERC721Metadata");
        require(
            IERC165(tokenContract).supportsInterface(interfaceIdEnumerable),
            "Does not support ERC721Enumerable");

        contracts[tokenContract].name = IERC721Metadata(tokenContract).name();
        contracts[tokenContract].tokenContract = tokenContract;

        try ITux(tokenContract).owner() returns(address owner) {
            if (owner != address(0)) {
                _collections[owner].add(tokenContract);
            }
        } catch {}

        _rankedContracts.add(tokenContract);

        ITuxERC20(tuxERC20).mint(msg.sender, 1 * 10**18);
    }

    function makeOffer(address tokenContract, uint256 tokenId)
        public
        payable
        override
    {
        require(
            IERC165(tokenContract).supportsInterface(interfaceId),
            "Does not support ERC721");

        bytes32 auctionHash = keccak256(abi.encode(tokenContract, tokenId));
        require(
            tokenAuction[auctionHash] == 0,
            "Auction exists");

        _lastOfferId += 1;
        uint256 offerId = _lastOfferId;

        offers[offerId] = Offer({
            tokenContract: tokenContract,
            tokenId: tokenId,
            from: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp
        });

        _tokenOffers[auctionHash].add(offerId);

        ITuxERC20(tuxERC20).mint(msg.sender, 1 * 10**18);
    }

    function acceptOffer(uint256 offerId)
        public
        override
    {
        IAuctions.Offer storage offer = offers[offerId];
        require(
            offer.tokenContract != address(0),
            "Does not exist");
        require(
            msg.sender == IERC721(offer.tokenContract).ownerOf(offer.tokenId) ||
            msg.sender == IERC721(offer.tokenContract).getApproved(offer.tokenId),
            "Not owner or approved");

        IERC721(offer.tokenContract).safeTransferFrom(msg.sender, offer.from, offer.tokenId);

        _handleOutgoingBid(msg.sender, offer.amount);

        bytes32 auctionHash = keccak256(abi.encode(offer.tokenContract, offer.tokenId));
        _tokenOffers[auctionHash].remove(offerId);

        delete offers[offerId];

        ITuxERC20(tuxERC20).mint(msg.sender, 1 * 10**18);
    }

    function cancelOffer(uint256 offerId)
        public
        override
    {
        IAuctions.Offer storage offer = offers[offerId];
        require(
            offer.from == msg.sender,
            "Not owner or missing");

        _handleOutgoingBid(msg.sender, offer.amount);

        bytes32 auctionHash = keccak256(abi.encode(offer.tokenContract, offer.tokenId));
        _tokenOffers[auctionHash].remove(offerId);

        delete offers[offerId];
    }

    function updateHouseRank(uint256 houseId)
        public
        override
    {
        require(
            _rankedHouses.scoreOf(houseId) < houses[houseId].bids,
            "Rank up to date");

        _rankedHouses.rankScore(houseId, houses[houseId].bids);

        ITuxERC20(tuxERC20).mint(msg.sender, 1 * 10**18);
    }

    function updateCreatorRank(address creator)
        public
        override
    {
        require(
            _rankedCreators.scoreOf(creator) < creatorStats[creator].bids,
            "Rank up to date");

        _rankedCreators.rankScore(creator, creatorStats[creator].bids);

        ITuxERC20(tuxERC20).mint(msg.sender, 1 * 10**18);
    }

    function updateCollectorRank(address collector)
        public
        override
    {
        require(
            _rankedCollectors.scoreOf(collector) < collectorStats[collector].bids,
            "Rank up to date");

        _rankedCollectors.rankScore(collector, collectorStats[collector].bids);

        ITuxERC20(tuxERC20).mint(msg.sender, 1 * 10**18);
    }

    function updateContractRank(address tokenContract)
        public
        override
    {
        require(
            _rankedContracts.scoreOf(tokenContract) < contracts[tokenContract].bids,
            "Rank up to date");

        _rankedContracts.rankScore(tokenContract, contracts[tokenContract].bids);

        ITuxERC20(tuxERC20).mint(msg.sender, 1 * 10**18);
    }

    function feature(uint256 auctionId, uint256 amount)
        public
        override
    {
        require(
            auctions[auctionId].tokenOwner == msg.sender,
            "Not token owner");
        ITuxERC20(tuxERC20).feature(auctionId, amount, msg.sender);
    }

    function cancelFeature(uint256 auctionId)
        public
        override
    {
        require(
            auctions[auctionId].tokenOwner == msg.sender,
            "Not token owner");
        ITuxERC20(tuxERC20).cancel(auctionId, msg.sender);
    }

    function _handleOutgoingBid(address to, uint256 amount) internal {
        require(
            _safeTransferETH(to, amount),
            "ETH transfer failed");
    }

    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{value: value}(new bytes(0));
        return success;
    }

    function _cancelAuction(uint256 auctionId) internal {
        IAuctions.Auction storage auction = auctions[auctionId];

        IERC721(auction.tokenContract).safeTransferFrom(address(this), auction.tokenOwner, auction.tokenId);

        uint256 houseId = auction.houseId;
        if (houseId > 0) {
            _houseAuctions[houseId].remove(auctionId);
            if (houses[houseId].activeAuctions > 0) {
                houses[houseId].activeAuctions -= 1;
            }
        }
        else {
            _activeAuctions.remove(auctionId);
        }

        auction.approved = false;
        bytes32 auctionHash = keccak256(abi.encode(auction.tokenContract, auction.tokenId));
        _previousTokenAuctions[auctionHash].add(auctionId);
        delete tokenAuction[auctionHash];

        emit AuctionCanceled(
            auctionId
        );
    }
}
