pragma solidity ^0.6.0;
import "./SafeMath.sol";

import "./IERC721.sol";
import "./IERC1155.sol";

//import "./IERC20.sol";

import "./IAirPair.sol";

contract DutchAuction {
    using SafeMath for uint256;

    struct Auction {
        uint256 id;
        address seller;
        uint256 tokenId;
        uint128 startingPrice; // wei
        uint128 endingPrice; // wei
        uint64 duration; // seconds
        uint64 startedAt; // time
    }

    address public NFTContract;
    uint256 public NFTtype;

    // the accepted "air" token  example AIRMEME, i imagine we need one auction contract for each pool of nfts
    IAirPair public acceptedToken;

    uint256 public daoFee;
    address public daoAddress;

    uint64 public auctionId; // max is 18446744073709551615

    mapping(uint256 => Auction) internal auctionIdToAuction;

    modifier isTokenOwner(uint256 _id) {
        require(nftOwner(_id), "You must own the NFT to use this feature");
        _;
    }

    event AuctionCreated(
        uint256 auctionId,
        uint256 tokenId,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration
    );
    event AuctionCancelled(uint64 auctionId, uint256 tokenId);
    event AuctionSuccessful(
        uint256 auctionId,
        uint256 tokenId,
        uint256 totalPrice,
        address winner
    );

    constructor(
        address _NFTAddress,
        uint256 _type,
        address _acceptedToken,
        address _daoAddress,
        uint256 _daoFee
    ) public {
        NFTContract = _NFTAddress;
        NFTtype = _type;
        acceptedToken = IAirPair(_acceptedToken);
        daoAddress = _daoAddress;
        daoFee = _daoFee;
    }

    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    ) public isTokenOwner(_tokenId) {
        // check storage requirements
        require(_startingPrice < 340282366920938463463374607431768211455); // 128 bits
        require(_endingPrice < 340282366920938463463374607431768211455); // 128 bits
        require(_duration <= 18446744073709551615); // 64 bits

        require(_duration >= 1 minutes);
        // maybe we should transfer the nft into contract instead?

        Auction memory auction = Auction(
            uint64(auctionId),
            msg.sender,
            uint256(_tokenId),
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );

        auctionIdToAuction[auctionId] = auction;

        emit AuctionCreated(
            uint64(auctionId),
            uint256(_tokenId),
            uint256(auction.startingPrice),
            uint256(auction.endingPrice),
            uint256(auction.duration)
        );

        auctionId++;
    }

    function getAuctionByAuctionId(uint256 _auctionId)
        public
        view
        returns (
            uint256,
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        Auction storage auction = auctionIdToAuction[_auctionId];
        require(auction.startedAt > 0);

        auction.id;
        auction.seller;
        auction.tokenId;
        auction.startingPrice;
        auction.endingPrice;
        auction.duration;
        auction.startedAt;
    }

    function cancelAuctionByAuctionId(uint64 _auctionId) public {
        Auction storage auction = auctionIdToAuction[_auctionId];

        require(auction.startedAt > 0);
        require(msg.sender == auction.seller);

        delete auctionIdToAuction[_auctionId];
        emit AuctionCancelled(_auctionId, auction.tokenId);
    }

    function bid(uint256 _auctionId, uint256 _bid) public {
        Auction storage auction = auctionIdToAuction[_auctionId];
        require(auction.startedAt > 0);

        uint256 price = getCurrentPrice(auction);
        require(_bid >= price);

        address seller = auction.seller;
        uint256 auctionId_temp = auction.id;

        delete auctionIdToAuction[auctionId_temp];

        if (price > 0) {
            uint256 sellerProceeds = price;
            require(
                acceptedToken.transferFrom(
                    msg.sender,
                    seller,
                    sellerProceeds.mul(95).div(100)
                ) &&
                    acceptedToken.transferFrom(
                        msg.sender,
                        daoAddress,
                        sellerProceeds.mul(5).div(100)
                    ),
                "Unsuccessfull payment"
            );
        }

        transferNft(seller, msg.sender, auction.tokenId);

        emit AuctionSuccessful(auctionId_temp, auctionId_temp, price, msg.sender);
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
            int256 totalPriceChange = int256(_auction.endingPrice) -
                int256(_auction.startingPrice);

            int256 currentPriceChange = (totalPriceChange *
                int256(secondsPassed)) / int256(_auction.duration);

            int256 currentPrice = int256(_auction.startingPrice) +
                currentPriceChange;

            return uint256(currentPrice);
        }
    }

    // maybe we can rethink this for less gas?
    function transferNft(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        if (NFTtype == 721) {
            IERC721(NFTContract).safeTransferFrom(_from, _to, _tokenId);
        } else if (NFTtype == 1155) {
            IERC1155(NFTContract).safeTransferFrom(_from, _to, _tokenId, 1, "");
        }
    }

    function nftOwner(uint256 _tokenId) public view returns (bool) {
        if (NFTtype == 721) {
            IERC721(NFTContract).ownerOf(_tokenId) == msg.sender;
        } else if (NFTtype == 1155) {
            IERC1155(NFTContract).balanceOf(msg.sender, _tokenId) >= 1;
        }
    }
}
