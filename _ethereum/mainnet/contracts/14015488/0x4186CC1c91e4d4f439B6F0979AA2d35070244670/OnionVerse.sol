// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ECDSA.sol";

contract OnionVerse is ERC721, Ownable {
  using Strings for uint256;
  uint256 public totalSupply;
  string private _baseURIExtended;

  constructor() ERC721('Onion Verse', 'OV') {}

  function withdraw(address to) public onlyOwner {
    uint256 balance = address(this).balance;
    payable(to).transfer(balance);
  }

  function preserveMint(uint tokenQuantity, address to) public onlyOwner {
    _mintOnionVerse(tokenQuantity, to);
  }

  function getTotalSupply() public view returns (uint256) {
    return totalSupply;
  }

  function getOnionVerseByOwner(address _owner) public view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](tokenCount);
    uint256 _index;
    uint256 _loopThrough = totalSupply;
    for (uint256 i; i < _loopThrough; i++) {
      bool _exists = _exists(i);
      if (_exists){
        if (ownerOf(i) == _owner) { tokenIds[_index] = i; _index++;}
      }      
      else if (!_exists && tokenIds[tokenCount-1] == 0) {_loopThrough++;}
    }
    return tokenIds;
  }

  function _mintOnionVerse(uint256 tokenQuantity, address recipient) internal {
    uint256 supply = totalSupply;
    for (uint256 i = 0; i < tokenQuantity; i++) {
      _mintInternal(recipient, supply + i);
    }
  }
   function _mintInternal(address to_, uint256 tokenId) internal {
    totalSupply++;
    _mint(to_, tokenId);
  }

  function setBaseURI(string memory baseURI_) external onlyOwner {
    _baseURIExtended = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseURIExtended;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), 'ERC721Versedata: URI query for nonexistent token');
    return string(abi.encodePacked(_baseURI(), tokenId.toString()));
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}