// contracts/CryptoOx.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract CryptoOx is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
  uint256 public constant MAX_SUPPLY = 8;
  string _metadataBaseURI;

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdCounter;

  constructor() ERC721('CryptoOx', 'COX') {
    _metadataBaseURI = 'https://cryptoox.co/api/ox/';

    _tokenIdCounter.increment();
    for (uint256 i = 1; i <= 8; i++) {
      if (totalSupply() < MAX_SUPPLY) {
        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();
      }
    }
  }

  function _baseURI() internal view override returns (string memory) {
    return _metadataBaseURI;
  }

  function baseURI() public view virtual returns (string memory) {
    return _baseURI();
  }

  function setBaseURI(string memory baseUri) public onlyOwner {
    _metadataBaseURI = baseUri;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function safeMint() public view onlyOwner {
    require(false, 'No more ox can be minted');
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    // This forwards all available gas. Be sure to check the return value!
    (bool success, ) = msg.sender.call{ value: balance }('');

    require(success, 'Transfer failed.');
  }

  receive() external payable {}
}
