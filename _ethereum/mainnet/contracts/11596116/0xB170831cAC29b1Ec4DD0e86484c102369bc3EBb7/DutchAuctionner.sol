pragma solidity ^0.6.0;
import "./Initializable.sol";

import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

import "./IERC721.sol";
import "./IERC1155.sol";

import "./IAirPair.sol";

contract DutchAuctionner is Initializable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    struct Auction {
        uint256 id;
        address seller;
        address airPair;
        uint256 tokenId;
        uint256 startingPrice; // wei
        uint256 endingPrice; // wei
        uint256 duration; // seconds
        uint256 startedAt; // time
    }

    uint256 public daoFee;
    address public daoAddress;

    uint256 public auctionId; // max is 18446744073709551615

    mapping(uint256 => Auction) internal auctionIdToAuction;

    mapping(address => uint256) internal nftTypes;
    mapping(address => address) internal nftAddresses;

    modifier isTokenOwner(address _airPair, uint256 _id) {
        require(nftOwner(_airPair, _id), "You must own the NFT to use this feature");
        _;
    }

    event AuctionCreated(
        uint256 auctionId,
        address indexed seller,
        address indexed airPair,
        uint256 tokenId,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration
    );
    event AuctionCancelled(uint64 auctionId, address indexed seller, address indexed airPair, uint256 tokenId);

    event AuctionSuccessful(
        uint256 auctionId,
        address indexed seller,
        address indexed airPair,
        uint256 tokenId,
        uint256 totalPrice,
        address winner
    );

    constructor(
    ) public {
    }

     function initialize(
        address _daoAddress,
        uint256 _daoFee) public initializer {
        OwnableUpgradeable.__Ownable_init();
        daoAddress = _daoAddress;
        daoFee = _daoFee;
    }

    function createAuction(
        address _airPair,
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    ) public isTokenOwner(_airPair, _tokenId) /* Not sure this is needed as we'll transfer */ {
        require(_duration >= 1 minutes);
        // maybe we should transfer the nft into contract instead?

        IAirPair airpair = IAirPair(_airPair);

        Auction memory auction = Auction(
            uint64(auctionId),
            msg.sender,
            _airPair,
            _tokenId,
            _startingPrice,
            _endingPrice,
            _duration,
            uint256(now)
        );

        if (nftTypes[_airPair] == 0) {
            nftTypes[_airPair] = airpair.nftType();
            nftAddresses[_airPair] = airpair.nftAddress();
        }
        transferNft(auction.airPair, msg.sender, address(this), auction.tokenId);

        auctionIdToAuction[auctionId] = auction;

        emit AuctionCreated(
            auctionId,
            msg.sender,
            _airPair,
            _tokenId,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration
        );

        auctionId++;
    }

    function getAuctionByAuctionId(uint256 _auctionId)
        public
        view
        returns (
            uint256 _id,
            address _seller,
            address _airPair,
            uint256 _tokenId,
            uint256 _startingPrice,
            uint256 _endingPrice,
            uint256 _duration,
            uint256 _startedAt,
            uint256 _currentPrice
        )
    {
        Auction storage auction = auctionIdToAuction[_auctionId];
        require(auction.startedAt > 0); // Not sure why this
        _id = auction.id;
        _seller = auction.seller;
        _airPair = address(auction.airPair);
        _tokenId = auction.tokenId;
        _startingPrice = auction.startingPrice;
        _endingPrice = auction.endingPrice;
        _duration = auction.duration;
        _startedAt = auction.startedAt;
        _currentPrice = getCurrentPrice(auction);
    }

    function cancelAuctionByAuctionId(uint64 _auctionId) public {
        Auction storage auction = auctionIdToAuction[_auctionId];

        require(auction.startedAt > 0);
        require(msg.sender == auction.seller);

        delete auctionIdToAuction[_auctionId];
        emit AuctionCancelled(_auctionId, auction.seller, address(auction.airPair), auction.tokenId);
        transferNft(auction.airPair, address(this), auction.seller, auction.tokenId);

    }

    function bid(uint256 _auctionId, uint256 _bid) public {
        Auction storage auction = auctionIdToAuction[_auctionId];
        require(auction.startedAt > 0);

        uint256 price = getCurrentPrice(auction);
        require(_bid >= price);

        address seller = auction.seller;
        uint256 auctionId_temp = auction.id;
        IAirPair airPair = IAirPair(auction.airPair);

        delete auctionIdToAuction[auctionId_temp];

        if (price > 0) {
            uint256 sellerProceeds = price;
            require(
                airPair.transferFrom(
                    msg.sender,
                    seller,
                    sellerProceeds.mul(95).div(100)
                ) &&
                    airPair.transferFrom(
                        msg.sender,
                        daoAddress,
                        sellerProceeds.mul(5).div(100)
                    ),
                "Unsuccessfull payment"
            );
        }

        transferNft(auction.airPair, seller, msg.sender, auction.tokenId);

        emit AuctionSuccessful(auctionId_temp, auction.seller, address(airPair), auction.tokenId, price, msg.sender);
    }

    function getCurrentPriceByAuctionId(uint64 _auctionId)
        public
        view
        returns (uint256)
    {
        Auction storage auction = auctionIdToAuction[_auctionId];
        return getCurrentPrice(auction);
    }

    function getCurrentPrice(Auction storage _auction)
        internal
        view
        returns (uint256)
    {
        require(_auction.startedAt > 0);
        uint256 secondsPassed = 0;

        secondsPassed = now - _auction.startedAt;

        if (secondsPassed >= _auction.duration) {
            return _auction.endingPrice;
        } else {
            uint256 totalPriceChange = uint256(_auction.endingPrice) -
                uint256(_auction.startingPrice);

            uint256 currentPriceChange = (totalPriceChange *
                uint256(secondsPassed)) / uint256(_auction.duration);

            uint256 currentPrice = uint256(_auction.startingPrice) +
                currentPriceChange;

            return uint256(currentPrice);
        }
    }

    // maybe we can rethink this for less gas?
    function transferNft(
        address _airPair,
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        if (nftTypes[_airPair] == 721) {
            IERC721(nftAddresses[_airPair]).safeTransferFrom(_from, _to, _tokenId);
        } else if (nftTypes[_airPair] == 1155) {
            IERC1155(nftAddresses[_airPair]).safeTransferFrom(_from, _to, _tokenId, 1, "");
        }
    }

    function nftOwner(address _airPair, uint256 _tokenId) public view returns (bool) {
        if (nftTypes[_airPair] == 721) {
            IERC721(nftAddresses[_airPair]).ownerOf(_tokenId) == msg.sender;
        } else if (nftTypes[_airPair] == 1155) {
            IERC1155(nftAddresses[_airPair]).balanceOf(msg.sender, _tokenId) >= 1;
        }
    }
}
