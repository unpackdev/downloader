// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./OwnableUpgradeable.sol";
import "./AddressUpgradeable.sol";

import "./IRoyaltyBase.sol";

abstract contract RoyaltyBase is IRoyaltyBase, OwnableUpgradeable {
  using Address for address;

  mapping(uint256 => address) public creators;
  uint256 public royaltyPercentageForCreator; // 100 for 1%
  uint256 public royaltyPercentageForAdmin;

  function setRoyaltyPercentageForCreator(uint256 _royaltyPercentageForCreator)
    external
    virtual
    override
    onlyOwner
  {
    royaltyPercentageForCreator = _royaltyPercentageForCreator;
  }

  function setRoyaltyPercentageForAdmin(uint256 _royaltyPercentageForAdmin)
    external
    virtual
    override
    onlyOwner
  {
    royaltyPercentageForAdmin = _royaltyPercentageForAdmin;
  }

  function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external
    view
    virtual
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    receiver = creators[tokenId];
    royaltyAmount = (salePrice * royaltyPercentageForCreator) / 10000;
  }

  function royaltyInfoAdmin(uint256 salePrice)
    external
    view
    virtual
    override
    returns (uint256 royaltyAmount)
  {
    royaltyAmount = (salePrice * royaltyPercentageForAdmin) / 10000;
  }

  function totalRoyaltyFee(uint256 salePrice)
    external
    view
    virtual
    override
    returns (uint256 royaltyFee)
  {
    royaltyFee = (salePrice * (royaltyPercentageForCreator + royaltyPercentageForAdmin)) / 10000;
  }
}
