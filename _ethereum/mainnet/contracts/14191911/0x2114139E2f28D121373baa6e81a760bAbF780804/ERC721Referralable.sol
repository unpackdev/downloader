// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";

abstract contract ERC721Referralable is Ownable, ERC721Enumerable {
  address public charityDonationAddress;
  uint256 public singleReferalValue;
  uint256 public totalReferrals;
  uint256 public totalCharityDonations;
  mapping(uint256 => uint256) public totalReferralsByToken;

  function sendReferrals(uint256 mintedCount, uint256 refTokenId) internal {
    if (refTokenId > 0 && _exists(refTokenId)) {
      sendToTokenOwner(mintedCount, refTokenId);
    } else {
      sendToCharity(mintedCount);
    }
  }

  function sendToTokenOwner(uint256 mintedCount, uint256 refTokenId) private {
    address tokenOwner = ownerOf(refTokenId);
    uint256 value = mintedCount * singleReferalValue;
    totalReferrals += mintedCount;
    totalReferralsByToken[refTokenId] += mintedCount;

    sendFunds(value, tokenOwner);
  }

  function sendToCharity(uint256 mintedCount) private {
    uint256 value = mintedCount * singleReferalValue;
    totalCharityDonations += mintedCount;

    sendFunds(value, charityDonationAddress);
  }

  function sendFunds(uint256 value, address to) private returns (bool) {
    (bool sent, ) = to.call{ value: value }('');

    return sent;
  }

  function setReferalValue(uint256 _val) external onlyOwner {
    singleReferalValue = _val;
  }
}
