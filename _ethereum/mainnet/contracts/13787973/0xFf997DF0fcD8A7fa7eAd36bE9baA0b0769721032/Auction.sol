// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract Token is Ownable, ERC721Enumerable, ERC721Burnable {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIdTracker;

  uint256 public constant MAX_TOKENS = 500;
  uint256 public constant MINT_FEE = 15 * 10**16;
  uint256 public constant MAX_MINT_COUNT = 5;
  string private _baseTokenURI = "ipfs://QmUtaT5HWkfQfTsy1M3xJ4HyBCw1EubZYd72QvAVRwzAwX/";

  constructor() ERC721("Celestia", "CLSA") {
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }

  function mint(uint256 _count) public payable {
    uint256 nextId = _tokenIdTracker.current();
    require(nextId + _count <= MAX_TOKENS, "Mint limit");
    require(msg.value >= MINT_FEE.mul(_count));

    for (uint256 i = 0; i < _count; i++) {
      _mintSingle();
    }
  }

  function _mintSingle() private {
    uint256 nextId = _tokenIdTracker.current();
    _safeMint(msg.sender, nextId);
    _tokenIdTracker.increment();
  }

  function withdraw() public onlyOwner {
    (bool success, ) = owner().call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}