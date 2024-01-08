// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract Token is ERC721Enumerable, Ownable, Pausable {
  using Strings for uint256;

  // map trait fingerprints existence
  mapping (string => bool) private mintedFellas;
  // map token id to trait fingerprints
  mapping (uint => string) private tokensToTraits;

  uint baseCost = 100000000000000000;
  uint16 maxNonOwnerSupply = 50;
  uint16 maxSupply = maxNonOwnerSupply + 6000;

  string baseUri = "https://oddfellas.art/metadata/";

  constructor (string memory _name, string memory _symbol) ERC721(_name, _symbol) {
      _pause();
  }

  function purchase(string calldata traits) external payable whenNotPaused {
    require((msg.value == baseCost || msg.sender == owner()), "ether amount incorrect");
    require((msg.sender != owner() && totalSupply() < maxNonOwnerSupply) ||
    (msg.sender == owner() && totalSupply() < maxSupply), "all fellas have been minted");
    require(!mintedFellas[traits], "fella already exists");

    uint id = totalSupply() + 1;
    _safeMint(msg.sender, id);
    tokensToTraits[id] = traits;
    mintedFellas[traits] = true;
  }

  function withdraw() external onlyOwner {
      uint balance = address(this).balance;
      payable(msg.sender).transfer(balance);
  }

  function changePrice(uint _basePrice) external onlyOwner {
      baseCost = _basePrice;
  }

  function getTraits(uint256 tokenId) external view returns (string memory) {
      require(_exists(tokenId), "nonexistent token");
      return tokensToTraits[tokenId];
  }

  function doesFingerprintExist(string calldata traitFingerprint) external view returns (bool) {
      return mintedFellas[traitFingerprint];
  }

  function pauseMinting() external onlyOwner {
      _pause();
  }

  function unpauseMinting() external onlyOwner {
      _unpause();
  }

  function setBaseURI(string calldata newBaseUri) external onlyOwner {
      baseUri = newBaseUri;
  }

  function _baseURI() override internal view virtual returns (string memory) {
      return baseUri;
  }

}
