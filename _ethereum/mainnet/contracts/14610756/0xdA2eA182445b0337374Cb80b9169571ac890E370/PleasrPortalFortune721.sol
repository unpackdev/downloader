//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./IERC721Metadata.sol";
import "./ERC721CreatorExtension.sol";
import "./IERC721CreatorCore.sol";
import "./Ownable.sol";

contract PleasrPortalFortune721 is ERC721CreatorExtension, Ownable {
  // Fortune contract 721: 0x89eCBEb233aA34C88c5d7d02D8113726dBC1bC78
  ERC721 private _fortuneContractChads;
  // pplpleasr 721 creator contract: 0x213a57c79ef27c079f7ac98c4737333c51a95b02
  IERC721CreatorCore private _creator;
  bool private _isActive;

  constructor(address creator, address redeemableContract) {
    _creator = IERC721CreatorCore(creator);
    _fortuneContractChads = ERC721(redeemableContract);
  }

  function setIsActive(bool isActive) external onlyOwner {
    _isActive = isActive;
  }

  function redeemWithTokenId(uint256[] calldata tokenIds) public {
    require(_isActive, "redemption not active");
    // Go through all chad tokenIds and redeem new token for user
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 id = tokenIds[i];
      require(
        _fortuneContractChads.ownerOf(id) == msg.sender,
        "Invalid tokenId"
      );
      // Burn
      _fortuneContractChads.transferFrom(msg.sender, address(0xdEaD), id);
      // Mint a new token assigning it the old uri
      _creator.mintExtension(msg.sender, _fortuneContractChads.tokenURI(id));
    }
  }
}
