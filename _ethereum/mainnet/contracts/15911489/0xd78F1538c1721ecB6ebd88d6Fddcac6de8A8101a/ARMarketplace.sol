//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IERC20.sol";

import "./ARClaimToken.sol";
import "./ARLibrary.sol";

contract ARMarketplace is Ownable {
  address public claimTokenAddress;
  address public paymentTokenAddress;

  struct Listing {
    address seller;
    uint256 tokenId;
    uint256 price;
  }

  event ListingCreated(uint256 tokenId, address claimOwner, uint256 price);
  event ListingCancelled(uint256 tokenId, address claimOwner);
  event PriceChanged(uint256 tokenId, uint256 lastPrice, address sender, uint256 newPrice);
  event ListingSold(uint256 tokenId, address buyer, address seller, uint256 price);
  event Attest(uint256 tokenId, address sender);

  mapping(uint256 => Listing) public listings; // tokenId => Listing
  mapping(uint256 => address) public attestations; // tokenId => attestation address
  mapping(address => bool) public attestationWhitelist; // attestor address => true/ false (whitelisted)

  constructor(address _claimTokenAddress, address _paymentTokenAddress) {
    claimTokenAddress = _claimTokenAddress;
    paymentTokenAddress = _paymentTokenAddress;
  }

  function attest(uint256 _tokenId) public {
    require(attestationWhitelist[msg.sender], "Not whitelisted");

    attestations[_tokenId] = msg.sender;

    emit Attest(_tokenId, msg.sender);
  }

  function createListing(uint256 tokenId, uint256 price) public {
    require(ARClaimToken(claimTokenAddress).ownerOf(tokenId) == msg.sender, "You are not the owner of this token");
    require(listings[tokenId].seller == address(0), "Token already listed");

    listings[tokenId] = Listing(msg.sender, tokenId, price);

    emit ListingCreated(tokenId, msg.sender, price);
  }

  function cancelListing(uint256 tokenId) public {
    require(listings[tokenId].seller == msg.sender, "You are not the seller of this token");

    delete listings[tokenId];

    emit ListingCancelled(tokenId, msg.sender);
  }

  function changeListingPrice(uint256 tokenId, uint256 newValue) public {
    require(ARClaimToken(claimTokenAddress).ownerOf(tokenId) == msg.sender, "You are not the owner of this token");
    require(listings[tokenId].seller != address(0), "Token not listed");

    uint256 lastPrice = listings[tokenId].price;
    listings[tokenId].price = newValue;

    emit PriceChanged(tokenId, lastPrice, msg.sender, newValue);
  }

  function buyItem(uint256 _tokenId) public {
    Listing memory listing = listings[_tokenId];

    require(listing.seller != address(0), "This token is not for sale");
    require(listing.seller != msg.sender, "You are the seller of this token");
    require(
      IERC20(paymentTokenAddress).balanceOf(msg.sender) >= listing.price,
      "You do not have enough tokens to buy this claim"
    );
    // collect payment from buyer
    IERC20(paymentTokenAddress).transferFrom(msg.sender, address(this), listing.price);
    // send payouts to beneficiaries
    _payoutBeneficiaries(_tokenId, listing.price);

    ARClaimToken(claimTokenAddress).transferFrom(listing.seller, msg.sender, _tokenId);

    delete listings[_tokenId];

    emit ListingSold(_tokenId, msg.sender, listing.seller, listing.price);
  }

  function _payoutBeneficiaries(uint256 _tokenId, uint256 listPrice) internal {
    ARClaimToken claimToken = ARClaimToken(claimTokenAddress);
    ARLibrary.Claim memory claim = claimToken.getClaim(_tokenId);

    uint256 totalPercent = 0;
    for (uint256 i = 0; i < claim.beneficiaries.length; i++) {
      totalPercent += claim.percentages[i];
    }
    require(totalPercent <= 10000, "Total payout percentage is greater than 100%");

    for (uint256 i = 0; i < claim.beneficiaries.length; i++) {
      uint256 amount = (listPrice * claim.percentages[i]) / 10000;
      IERC20(paymentTokenAddress).transfer(claim.beneficiaries[i], amount);
    }

    if (totalPercent < 10000) {
      uint256 amount = (listPrice * (10000 - totalPercent)) / 10000;
      IERC20(paymentTokenAddress).transfer(claim.creator, amount);
    }
  }

  // VIEW FUNCTIONS
  function getListing(uint256 _tokenId) public view returns (Listing memory) {
    return listings[_tokenId];
  }

  function getAttestation(uint256 _tokenId) public view returns (address) {
    return attestations[_tokenId];
  }

  // ADMIN FUNCTIONS
  function setClaimTokenAddress(address _claimTokenAddress) public onlyOwner {
    claimTokenAddress = _claimTokenAddress;
  }

  function setPaymentTokenAddress(address _paymentTokenAddress) public onlyOwner {
    paymentTokenAddress = _paymentTokenAddress;
  }

  function addWhitelistedAttestor(address _attestor) public onlyOwner {
    attestationWhitelist[_attestor] = true;
  }

  function removeWhitelistedAttestor(address _attestor) public onlyOwner {
    attestationWhitelist[_attestor] = false;
  }
}
