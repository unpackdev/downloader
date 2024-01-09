// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

//              _____
//     ___..--""      `.
//_..-'               ,'
//                  ,'
//   (|\          ,'
//      ________,'
//   ,.`/`./\/`/
//  /-'
//   `',^/\/\
//_________,'
//

// SSS

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract SharkCouncil is ERC721Enumerable, Ownable{
  using Strings for uint256;

  constructor() ERC721("The Shark Council","SSSC"){}

  string private _contractURI;
  string private _tokenBaseURI;

  bool public locked;

  modifier notLocked {
      require(!locked, "Contract metadata methods are locked forever");
      _;
  }

  function mintList(address[] calldata receivers) external onlyOwner notLocked {

      for (uint256 i = 0; i < receivers.length; i++) {
          _safeMint(receivers[i], totalSupply() + 1);
      }
  }

  function mintBatch(address receiver, uint256 tokenQuantity) external onlyOwner notLocked {

      for (uint256 i = 0; i < tokenQuantity; i++) {
          _safeMint(receiver, totalSupply() + 1);
      }

  }

  function lockMetadataForever() external onlyOwner {
      locked = true;
  }

  function setContractURI(string calldata URI) external onlyOwner notLocked {
      _contractURI = URI;
  }

  function setBaseURI(string calldata URI) external onlyOwner notLocked {
      _tokenBaseURI = URI;
  }

  function contractURI() public view returns (string memory) {
      return _contractURI;
  }

  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
      require(_exists(tokenId), "Cannot query non-existent token");

      return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
  }
}