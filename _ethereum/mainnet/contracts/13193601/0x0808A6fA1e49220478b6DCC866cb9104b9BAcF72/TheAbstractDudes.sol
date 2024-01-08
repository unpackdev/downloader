// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";

import "./SafeMathUint.sol";
import "./ITheDudes.sol";

contract TheAbstractDudes is ERC721Enumerable, Ownable {
  using SafeMathUint for uint256;

  ITheDudes public theDudes;
  bool public isAirdropActive = false;
  string public baseURI;
  mapping(uint256 => bool) public claimedTokenIds;
  mapping(uint256 => string) public dnas;

  constructor (address theDudesAddress) ERC721("the abstract dudes", "TADUDES") {
    theDudes = ITheDudes(theDudesAddress);
  }

  function setIsAirdropActive(bool _isAirdropActive) public onlyOwner {
    isAirdropActive = _isAirdropActive;
  }

  function claimAll(address _owner) public {
    require(isAirdropActive, "Airdrop is not active yet.");
    require(!allClaimed(_owner), "All your tokens are claimed.");
    int256[] memory tokenIds = claimableOf(_owner);
    for (uint256 i = 0; i < tokenIds.length; i++) {
      if (tokenIds[i] != -1) {
        claim(uint256(tokenIds[i]));
      }
    }
  }

  function claim(uint256 _tokenId) public {
    require(isAirdropActive, "Airdrop is not active yet.");
    require(!claimedTokenIds[_tokenId], "This token is already minted.");
    require(theDudes.ownerOf(_tokenId) == msg.sender, "You should own the dude.");

    string memory theDudesDNA = theDudes.dudes(_tokenId);
    dnas[_tokenId] = theDudesDNA;
    claimedTokenIds[_tokenId] = true;
    _safeMint(msg.sender, _tokenId);
  }

  function claimableOf(address _owner) public view returns (int256[] memory) {
    uint256[] memory tokenIds = theDudes.tokensOfOwner(_owner);
    int256[] memory claimableTokenIds = new int256[](tokenIds.length);
    uint256 index = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      claimableTokenIds[i] = -1;
      if (theDudes.ownerOf(tokenId) == _owner) {
        if (!claimedTokenIds[tokenId]) {
          claimableTokenIds[index] = tokenId.toInt256Safe();
          index++;
        }
      }
    }
    return claimableTokenIds;
  }

  function allClaimed(address _owner) public view returns (bool) {
    int256[] memory tokenIds = claimableOf(_owner);
    bool allClaimed = true;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      if (tokenIds[i] != -1) {
        allClaimed = false;
      }
    }
    return allClaimed;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(_baseURI(), "/", dnas[_tokenId]));
  }

  function tokensOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 index;
      for (index = 0; index < tokenCount; index++) {
        result[index] = tokenOfOwnerByIndex(_owner, index);
      }
      return result;
    }
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
}
