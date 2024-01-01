// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Pausable.sol";
import "./ERC721URIStorage.sol";
import "./Context.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC2981.sol";

contract Koi2 is Context, ERC721Enumerable, ERC721Burnable, ERC721Pausable, ERC721URIStorage, Ownable, ERC2981 {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIdTracker;

  address private _royaltyReceiver;
  string private _baseTokenURI;

  constructor() ERC721("LOVH", "LOVH") {
    _baseTokenURI = 'https://storage.googleapis.com/tokenimv/koi2/metadata/1.json';
    _royaltyReceiver = msg.sender;
    _setDefaultRoyalty(_royaltyReceiver, 200); // 2%
  }

  function tokenURI(uint256 tokenId) public view override(ERC721URIStorage, ERC721) returns (string memory) {
    return _baseTokenURI;
  }

  function royaltyReceiver() external view returns (address) {
    return _royaltyReceiver;
  }

  function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external
    view
    virtual
    override
    returns (address, uint256)
  {
    return (_royaltyReceiver, (_salePrice * 200) / 10000);
  }

  //Only Owner
  function setRoyaltyReceiver (address receiver) external onlyOwner {
    _royaltyReceiver = receiver;
  }

  function mintBatch(uint[] memory tokenIds, address[] memory recipients) external onlyOwner {
    for (uint i = 0; i < recipients.length; i++) {
      _mintToken(tokenIds[i], recipients[i]);
    }
  }

  function mint(uint tokenId, address recipient) public virtual onlyOwner {
    _mintToken(tokenId, recipient);
  }

  function setBaseURI(string memory baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function pause() public virtual onlyOwner {
    _pause();
  }

  function unpause() public virtual onlyOwner {
    _unpause();
  }

  //Overwrite
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function _burn(uint256 tokenId) internal virtual override(ERC721URIStorage, ERC721) {
    super._burn(tokenId);
  }

  //Others
  function _mintToken(uint tokenId,address recipient) internal {
    _mint(recipient, tokenId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable, ERC2981) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}
