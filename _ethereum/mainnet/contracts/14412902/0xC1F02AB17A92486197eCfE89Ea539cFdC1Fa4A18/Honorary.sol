// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";

contract Honorary is
  ERC721,
  ERC721URIStorage,
  Pausable,
  Ownable,
  ERC721Burnable
{
  string private _tokenBaseURI;
  bool private _tokenBaseURILocked;
  uint256 private _tokenIdCounter;
  mapping(uint256 => string) private _tokenURIPaths;

  constructor(
    string memory tokenName_,
    string memory tokenSymbol_,
    string memory tokenBaseURI_
  ) ERC721(tokenName_, tokenSymbol_) {
    _tokenBaseURI = tokenBaseURI_;
  }

  function setTokenURIPath(uint256 tokenId_, string calldata arweaveURIPath_)
    public
    onlyOwner
  {
    _tokenURIPaths[tokenId_] = arweaveURIPath_;
  }

  function setTokenBaseURI(string calldata tokenBaseURI_) public onlyOwner {
    require(!_tokenBaseURILocked, "Token base URI is locked");
    _tokenBaseURI = tokenBaseURI_;
  }

  function lockTokenBaseURI() public onlyOwner {
    require(!_tokenBaseURILocked, "Token base URI is locked");
    _tokenBaseURILocked = true;
  }

  function tokenBaseURILocked() public view returns (bool) {
    return _tokenBaseURILocked;
  }

  function mintedSupply() public view returns (uint256) {
    return _tokenIdCounter;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function mint(address to_, string calldata arweaveURIPath_)
    public
    onlyOwner
    whenNotPaused
  {
    require(bytes(arweaveURIPath_).length > 0, "Missing arweave URI path");
    _safeMint(to_, mintedSupply());
    _tokenURIPaths[mintedSupply()] = arweaveURIPath_;
    _tokenIdCounter += 1;
  }

  function mintBatch(
    address[] calldata addresses_,
    string[] calldata arweaveURIPaths_
  ) public onlyOwner whenNotPaused {
    require(
      addresses_.length == arweaveURIPaths_.length,
      "Addresses & quantites not equal length"
    );
    for (uint256 i = 0; i < addresses_.length; i++) {
      mint(addresses_[i], arweaveURIPaths_[i]);
    }
  }

  function _baseURI() internal view override returns (string memory) {
    return _tokenBaseURI;
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, _tokenURIPaths[tokenId]))
        : "";
  }
}
