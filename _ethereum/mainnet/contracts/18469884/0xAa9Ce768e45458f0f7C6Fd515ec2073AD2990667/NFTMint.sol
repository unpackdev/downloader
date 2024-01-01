// SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.19;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract NFTMint is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
  enum Category { MrButerin, MrMusk, _99ETH, MrSatoshi, SatoshiNakomoto }
  uint256 private constant _maxTokensInCategory = 60;
  uint256 private _tokenIdCounter = 1;
  uint256 private _lastMintTime = block.timestamp;
  struct NFTData {
    uint256 id;
    Category category;
  }
  mapping(uint256 => NFTData) private nfts;
  mapping(Category => uint256) private categoryMintCount;

  constructor() ERC721("The 5 Satoshis", "TFS") Ownable(msg.sender) {}

  modifier onlyValidNFTId(uint256 _id) {
    require(_id >= 1 && _id < _tokenIdCounter, 'invalid token id');
    _;
  }

  event NFTMinted(address indexed recipient, uint256 tokenId, Category category);
  event NFTCategoryAssigned(uint256 id, Category category);
  event NFTBurned(uint256 tokenId);

  function getCategory(uint256 _id) public view onlyValidNFTId(_id) returns (Category category) {
    return nfts[_id].category;
  }

  function getNFTData(uint256 _id) public view onlyValidNFTId(_id) returns (NFTData memory) {
    return nfts[_id];
  }

  function getNextId() public view returns (uint256) {
    return _tokenIdCounter;
  }

  function getTokensInCategory(Category _category) public view returns (uint256) {
    return categoryMintCount[_category];
  }

  function burn(uint256 _id) public onlyOwner onlyValidNFTId(_id) {
    Category currentCategory = getCategory(_id);

    uint256 categoryCounter = categoryMintCount[currentCategory];
    categoryMintCount[currentCategory] = categoryCounter - 1;

    delete nfts[_id];
    
    _burn(_id);
    emit NFTBurned(_id);
  }

  function isLockedMint(address _recipient) public view returns (bool) {
    if (owner() == _recipient) return true;
    if (_lastMintTime <= block.timestamp) return true;

    return false;
  }

  function mint(
    address _recipient,
    Category _category,
    string memory _tokenURI
  ) public returns (uint256) {
    require(isLockedMint(msg.sender), "Mint is locked!");
    require(categoryMintCount[_category] < _maxTokensInCategory, "Category limit reached!");

    uint256 newTokenId = _tokenIdCounter;
    _safeMint(_recipient, newTokenId);
    _setTokenURI(newTokenId, _tokenURI);
    uint256 categoryId = categoryMintCount[_category] + 1;
    nfts[newTokenId] = NFTData(newTokenId, _category);
    categoryMintCount[_category] = categoryId;

    _tokenIdCounter += 1;
    _lastMintTime = block.timestamp + (60 * 60 * 24);

    emit NFTMinted(_recipient, newTokenId, _category);

    return newTokenId;
  }

  function transferContractOwnership(address newOwner) public onlyOwner {
    transferOwnership(newOwner);
  }

  function _update(address to, uint256 tokenId, address auth)
    internal
    override(ERC721, ERC721Enumerable)
    returns (address)
  {
    return super._update(to, tokenId, auth);
  }

  function _increaseBalance(address account, uint128 value)
    internal
    override(ERC721, ERC721Enumerable)
  {
    super._increaseBalance(account, value);
  }
  
  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }
  
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable, ERC721URIStorage)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
