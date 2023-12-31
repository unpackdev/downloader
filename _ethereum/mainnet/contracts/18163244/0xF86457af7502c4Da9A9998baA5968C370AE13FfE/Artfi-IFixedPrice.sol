// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct LazyMintData {
  uint256 offerId;
  uint256 tokenId;
  address tokenContract;
  uint256 quantity;
  uint256 price;
  address seller;
  address buyer;
  string currency;
}

interface ArtfiIFixedPrice {

    struct Payout {
    address currency;
    address seller;
    address buyer;
    uint256 tokenId;
    address tokenAddress;
    uint256 quantity;
    address[] refundAddresses;
    uint256[] refundAmount;
    bool soldout;
  }

  function isSaleSupportedTokens(
    string memory tokenName_
  ) external view returns (bool tokenExist_);

  function lazyMint(LazyMintData calldata lazyMintData_) external;

  function enableDisableSaleToken(
        string memory tokenName_,
        bool enable_
    ) external;
}
