// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./Counters.sol";

contract Marataba is ERC721Tradable {
  using Strings for uint256;

  string public uriPrefix = "";

  constructor(address _proxyRegistryAddress)
    ERC721Tradable(
      "Marataba x Meta Lion Auction",
      "MMLA",
      _proxyRegistryAddress
    )
  {}

  function baseTokenURI() public view returns (string memory) {
    return uriPrefix;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    return string(abi.encodePacked(baseTokenURI(), _tokenId.toString()));
  }

  function withdraw() external onlyOwner {
    (bool os, ) = payable(owner()).call{ value: address(this).balance }("");
    require(os);
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }
}
