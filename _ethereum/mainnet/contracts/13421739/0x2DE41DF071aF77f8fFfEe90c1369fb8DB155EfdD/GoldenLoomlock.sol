// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";

contract GoldenLoomlock is ERC721, ERC721Enumerable, Pausable, Ownable, ERC721Burnable {
  using Counters for Counters.Counter;

  uint256 public immutable maxSupply;

  Counters.Counter private _tokenIdCounter;
  string private _tokenBaseURI;

  constructor(
    uint256 maxSupply_,
    string memory tokenBaseURI_
  ) ERC721("golden loomlock", "GL") {
    maxSupply = maxSupply_;
    _tokenBaseURI = tokenBaseURI_;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function setTokenBaseURI(string calldata tokenBaseURI_) external onlyOwner {
    _tokenBaseURI = tokenBaseURI_;
  }

  function mintedSupply() public view returns (uint256) {
    return _tokenIdCounter.current();
  }

  function mint(address to) public onlyOwner {
    require(mintedSupply() < maxSupply, "Max supply minted");
    _safeMint(to, _tokenIdCounter.current());
    _tokenIdCounter.increment();
  }

  // Provide an array of addresses and a corresponding array of quantities.
  function mintBatch(address[] calldata addresses, uint256[] calldata quantities) external onlyOwner {
    require(addresses.length == quantities.length, "Addresses & quantites length not equal");
    for (uint256 i = 0; i < addresses.length; i++) {
      for (uint256 j = 0; j < quantities[i]; j++) {
        mint(addresses[i]);
      }
    }
  }

  function addressHoldings(address _addr) public view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_addr);
    uint256[] memory tokens = new uint256[](tokenCount);
    for (uint256 i = 0; i < tokenCount; i++) {
      tokens[i] = tokenOfOwnerByIndex(_addr, i);
    }
    return tokens;
  }

  function _baseURI() internal view override returns (string memory) {
    return _tokenBaseURI;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(super.tokenURI(tokenId), ".json")) : "";
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
  internal whenNotPaused
  override(ERC721, ERC721Enumerable)
  {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  // The following functions are overrides required by Solidity.

  function supportsInterface(bytes4 interfaceId)
  public
  view
  override(ERC721, ERC721Enumerable)
  returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
