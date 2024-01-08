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

contract TheDudesFactory is ERC721Enumerable, Ownable {
  using Strings for *;

  mapping(uint256 => string) public tokenURIs;

  constructor () ERC721("the dudes factory", "DUDF") {}

  function mint(address _account, string calldata _tokenURI) public onlyOwner {
    uint256 tokenId = totalSupply();
    tokenURIs[tokenId] = _tokenURI;
    _safeMint(_account, tokenId);
  }

  function updateTokenURI(uint256 _tokenId, string calldata _tokenURI) public onlyOwner {
    tokenURIs[_tokenId] = _tokenURI;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    return tokenURIs[_tokenId];
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
}
