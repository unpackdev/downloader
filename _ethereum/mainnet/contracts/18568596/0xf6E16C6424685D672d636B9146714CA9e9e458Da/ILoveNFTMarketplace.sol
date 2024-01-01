// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "./ILoveRoles.sol";
import "./ILoveNFTShared.sol";

interface ILoveNFTMarketplace is ILoveRoles {
  enum TokenType {
    ERC721,
    ERC1155
  }

  struct NFT {
    address addr;
    uint256 tokenId;
  }

  struct ListingParams {
    NFT nft;
    uint256 price;
    uint256 startTime;
    uint256 endTime;
  }

  struct ListNFT {
    NFT nft;
    TokenType tokenType;
    address seller;
    uint256 price;
    uint256 startTime;
    uint256 endTime;
  }

  struct LazyListingParams {
    NFT nft;
    uint256 price;
    uint256 startTime;
    uint256 endTime;
    bytes32 uid;
  }

  struct OfferNFT {
    NFT nft;
    address offerer;
    uint256 offerPrice;
    TokenType tokenType;
    TokenRoyaltyInfo royaltyInfo;
    bool accepted;
  }

  struct OfferNFTParams {
    NFT nft;
    address offerer;
    uint256 price;
  }

  struct AuctionParams {
    NFT nft;
    uint256 initialPrice;
    uint256 minBidStep;
    uint256 startTime;
    uint256 endTime;
  }

  struct AuctionNFT {
    NFT nft;
    TokenType tokenType;
    address creator;
    uint256 initialPrice;
    uint256 minBidStep;
    uint256 startTime;
    uint256 endTime;
    address lastBidder;
    uint256 highestBid;
    TokenRoyaltyInfo royaltyInfo;
    address winner;
    bool success;
  }

  struct TokenRoyaltyInfo {
    address royaltyReceiver;
    uint256 royaltyAmount;
  }

  // events
  event ChangedPlatformFee(uint256 newValue);
  event ChangedFeeReceiver(address newFeeReceiver);

  event ListedNFT(
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price,
    address indexed seller,
    uint256 startTime,
    uint256 endTime
  );

  event CanceledListedNFT(
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price,
    address indexed seller,
    uint256 startTime,
    uint256 endTime
  );

  event BoughtNFT(
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price,
    address seller,
    address indexed buyer
  );
  event OfferedNFT(address indexed nftAddress, uint256 indexed tokenId, uint256 offerPrice, address indexed offerer);
  event CanceledOfferedNFT(
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 offerPrice,
    address indexed offerer
  );
  event AcceptedNFT(
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 offerPrice,
    address offerer,
    address indexed nftOwner
  );
  event CreatedAuction(
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price,
    uint256 minBidStep,
    uint256 startTime,
    uint256 endTime,
    address indexed creator
  );
  event PlacedBid(address indexed nftAddress, uint256 indexed tokenId, uint256 bidPrice, address indexed bidder);
  event CanceledAuction(address indexed nftAddress, uint256 indexed tokenId);

  event ResultedAuction(
    address indexed nftAddress,
    uint256 indexed tokenId,
    address creator,
    address indexed winner,
    uint256 price,
    address caller
  );

  function listNft(ListingParams calldata params) external returns (uint256);

  function getListedNFT(NFT calldata nft) external view returns (ListNFT memory);

  function cancelListedNFT(NFT calldata nft) external;

  function buyNFT(NFT calldata nft, uint256 price) external returns (uint256 priceWithRoyalty);

  function buyLazyListedNFT(
    ILoveNFTShared.MintRequest calldata params,
    bytes calldata signature
  ) external returns (uint256 priceWithRoyalty);

  function offerNFT(OfferNFTParams calldata params) external returns (uint256);

  function cancelOfferNFT(OfferNFTParams calldata params) external returns (uint256);

  function acceptOfferNFT(OfferNFTParams calldata params) external returns (uint256);

  function createAuction(AuctionParams calldata params) external;

  function cancelAuction(NFT calldata nft) external;

  function bidPlace(NFT calldata nft, uint256 bidPrice) external returns (uint256);

  function resultAuction(NFT calldata nft) external returns (uint256);

  function resultAuctions(NFT[] calldata nfts) external returns (uint256);

  function getAuction(NFT calldata nft) external view returns (AuctionNFT memory);

  function transferFee(uint256 amount) external;

  function setPlatformFee(uint256 newPlatformFee) external;

  function updateFeeReceiver(address newFeeReceiver) external;
}
