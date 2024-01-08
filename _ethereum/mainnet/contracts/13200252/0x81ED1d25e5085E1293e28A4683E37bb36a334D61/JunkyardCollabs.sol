// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721Tradable.sol";

contract JunkyardCollabs is ERC721Tradable {
  mapping(address => uint256) public allowance;
  constructor(address _proxyRegistryAddress)
      ERC721Tradable("JunkyardDogsCollab", "JDC", _proxyRegistryAddress)
  {
    allowance[msg.sender] = 8000;
  }

  function baseTokenURI() public override pure returns (string memory) {
      return "https://api.junkyarddogs.io/collab/";
  }

  function contractURI() public pure returns (string memory) {
      return "https://api.junkyarddogs.io/contract/";
  }

  function tokenURI(uint256 _tokenId) override public pure returns (string memory) {
      return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
  }

  function addWhitelistedAddress(address addr, uint256 amount) public onlyOwner {
    allowance[addr] = amount;
  }

  function removeWhitelistedAddress(address addr) public onlyOwner {
    allowance[addr] = 0;
  }

  function mint(address to, uint256 amount) public {
    require(allowance[msg.sender] >= amount, "You are not allowed to mint right now");
    for (uint256 i = 0; i < amount; i++) {
      uint256 newTokenId = _getNextTokenId();
      _mint(to, newTokenId);
      _incrementTokenId();
      allowance[msg.sender] = allowance[msg.sender] - 1;
    }
  }
}