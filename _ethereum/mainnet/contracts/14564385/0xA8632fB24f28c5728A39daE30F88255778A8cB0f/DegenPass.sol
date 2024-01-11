// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract DegenPass is ERC721, Ownable {
  using Strings for uint;
  using Counters for Counters.Counter;

  string public baseURI;
  string public baseExtension;
  uint public maxSupply = 3200;
  uint public maxTokensPerAddress = 1;
  Counters.Counter private _tokenId;

  constructor() ERC721("DegenPass", "DP") {}

  function totalSupply() public view returns (uint) {
    return _tokenId.current();
  }

  function tokenURI(uint tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension)): "";
  }

  function giftPass(address[] calldata _recipients) public onlyOwner {
      for (uint i = 0; i < _recipients.length; i++) {
        _tokenId.increment();
        _safeMint(_recipients[i], _tokenId.current());
      }
  }

  function setBaseURI(string memory _baseURI, string memory _baseExtension) public onlyOwner {
    baseURI = _baseURI;
    baseExtension = _baseExtension;
  }

}