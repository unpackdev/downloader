//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";

/**
  CryptoHoots: Alpha Parliament
  2021.10.01
 */
contract CryptoHootsAlpha is ERC721URIStorage, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  string public baseURI;
  string public baseContractURI;
  bool alphaMintLocked = false;

  event Hatched(uint256 indexed tokenId, address indexed owner);

  constructor(string memory _baseURI_, string memory _contractURI_)
  ERC721("CryptoHoots Alpha Parliament", "HOOTS") {
    setBaseURI(_baseURI_);
    baseContractURI = _contractURI_;
  }
    
  function hatch(address [] memory recipients) public onlyOwner {
    require(!alphaMintLocked, "Alpha mint permanently locked");

    for (uint256 i = 0; i < recipients.length; i++) {
      // initialize tokenId
      uint256 mintIndex = _tokenIds.current();
      
      // mint
      _safeMint(recipients[i], mintIndex);

      // increment id counter
      _tokenIds.increment();
      emit Hatched(mintIndex, msg.sender);
    }
  }

  function lockAlphaMint() public onlyOwner {
    alphaMintLocked = true;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory uri) public onlyOwner {
    baseURI = uri;
  }

  function contractURI() public view returns (string memory) {
    return baseContractURI;
  }
  
  function setContractURI(string memory uri) public onlyOwner {
    baseContractURI = uri;
  }

  function totalSupply() public view returns (uint256) {
    return _tokenIds.current();
  }
}
