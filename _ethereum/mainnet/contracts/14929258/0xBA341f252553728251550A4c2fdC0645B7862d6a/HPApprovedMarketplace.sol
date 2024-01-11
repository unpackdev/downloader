// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";

abstract contract HPApprovedMarketplace is Ownable {

  mapping(address => bool) internal _approvedMarketplaces;

  function setApprovedMarketplaceActive(address marketplaceAddress, bool approveMarket) public onlyOwner {
    _approvedMarketplaces[marketplaceAddress] = approveMarket;
  }
}