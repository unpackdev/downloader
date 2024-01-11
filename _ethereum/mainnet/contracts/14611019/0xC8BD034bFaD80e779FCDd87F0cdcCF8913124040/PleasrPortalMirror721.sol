//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./IERC721Metadata.sol";
import "./ERC721CreatorExtension.sol";
import "./IERC721CreatorCore.sol";
import "./Strings.sol";
import "./EnumerableSet.sol";
import "./Ownable.sol";

contract PleasrPortalMirror721 is Ownable, ERC721CreatorExtension {
  using EnumerableSet for EnumerableSet.UintSet;
  using Strings for uint256;
  // Mirror contract 721: 0xef3c951e22c65f6256746f4e227e19a5bcbf393c
  ERC721 private _mirrorContract;
  // pplpleasr 721 creator contract: 0x213a57c79ef27c079f7ac98c4737333c51a95b02
  IERC721CreatorCore private _creator;
  // Mirror contract is a shared contract with arbitrary tokenIds not exclusive to plsr, need to maintain a list of eligible Ids
  EnumerableSet.UintSet private _redeemableTokenIdsSet;
  // toggle for when contract is ready to let users start redeeming after redeemable list is ready
  bool private _isActive;
  // URI for metadata
  string private _baseURI;

  constructor(address creator, address redeemableContract) {
    _creator = IERC721CreatorCore(creator);
    _mirrorContract = ERC721(redeemableContract);
  }

  function setIsActive(bool isActive) external onlyOwner {
    _isActive = isActive;
  }

  function addTokenIdsToRedeemableList(uint256[] calldata tokenIds)
    external
    onlyOwner
  {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      _redeemableTokenIdsSet.add(tokenIds[i]);
    }
  }

  function removeTokenIdsFromRedeemableList(uint256[] calldata tokenIds)
    external
    onlyOwner
  {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      _redeemableTokenIdsSet.remove(tokenIds[i]);
    }
  }

  function setBaseURI(string memory baseURI) external onlyOwner {
    _baseURI = baseURI;
  }

  function redeemWithTokenId(uint256[] calldata tokenIds) public {
    require(_isActive, "Redemption not active");
    // Go through all mirror tokenIds and redeem new token for user
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 id = tokenIds[i];
      require(_redeemableTokenIdsSet.contains(id), "Invalid tokenId");
      require(
        _mirrorContract.ownerOf(id) == msg.sender,
        "Token with TokenId not found in your wallet"
      );
      // burn
      _mirrorContract.transferFrom(msg.sender, address(0xdEaD), id);
      // Mint a new token assigning it the old uri
      string memory uri = string(
        abi.encodePacked(_baseURI, id.toString(), ".json")
      );
      _creator.mintExtension(msg.sender, uri);
    }
  }
}
