// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ERC721Pausable.sol";
import "./EtherGrassOwners.sol";

contract EtherGrassPFP is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {
  using SafeMath for uint256;
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;
  Counters.Counter private _egOwnerMintCount;

  uint256 private _price = 5.0 * 10**16;
  bool private _eg_minting_allowed = false;
  bool private _public_minting_allowed = false;

  uint256 public constant MAX_ELEMENTS = 2222;
  uint256 public constant MAX_PER_MINT = 10;
  uint256 public constant MAX_PER_MINT_EG = 500;
  uint256 public constant MAX_EG_MINTS = 500;
  uint256 public constant EG_MINTS_PER_ID = 10;
  address public constant CREATOR_ADDRESS = 0xae2269584F7374257f35F41dD19689B804DaFFFb;

  string public baseTokenURI;
  string public baseExtension = ".json";

  mapping (uint256 => uint256) private _egTokenIdsUsed;

  event CreateEtherGrassPFP(uint256 indexed id);

  constructor(string memory baseURI) ERC721("X-B31", "EG") {
    setBaseURI(baseURI);
    pause(true);
    _tokenIds.increment();
  }

  modifier saleIsOpen {
    require(_totalSupply() <= MAX_ELEMENTS, "Sold Out");
    if (_msgSender() != owner()) {
      require(!paused(), "Sale Closed");
    }
    _;
  }

  // public / external

  function mint(address _to, uint256 _count) public payable saleIsOpen {
    require(_public_minting_allowed == true);
    require(_totalSupply() < MAX_ELEMENTS, "Sold Out");
    require(_totalSupply() + _count <= MAX_ELEMENTS, "Not Enough Left");
    require(_count <= MAX_PER_MINT, "Too Many");
    require(msg.value >= price(_count), "Below Price");

    for (uint256 i = 0; i < _count; i++) {
      _mintAnElement(_to);
    }
  }

  function etherGrassMint(address _to, uint256 _count, uint256[] memory _tokensId) public payable saleIsOpen {
    require(_eg_minting_allowed == true);
    require(_count <= MAX_PER_MINT_EG, "Over Max Mint");
    require(etherGrassMintsClaimable(_msgSender()) >= _count, "Not Enough Claimable");
    require(MAX_EG_MINTS.sub(_egTokenSupply()) > 0, "EtherGrass Mints Out");
    require(_count <= MAX_EG_MINTS.sub(_egTokenSupply()), "Not Enough EtherGrass Mints");
    require(_totalSupply() + _count <= MAX_ELEMENTS, "Not Enough Left");
    require(_totalSupply() <= MAX_ELEMENTS, "Sold Out");
    uint256 mintedSoFar = 0;

    for (uint256 i = 0; i < _tokensId.length; i++) {

      uint256  _tokenId = _tokensId[i];
      require(EtherGrassOwners.isEtherGrassToken(_tokenId), "Token Not EtherGrass");
      require(EtherGrassOwners.ownsToken(_msgSender(), _tokenId), "Unowned Token");
      uint256 mintsLeftOnToken = EG_MINTS_PER_ID - _egTokenIdsUsed[_tokenId];

      for (uint256 j = 0; j < mintsLeftOnToken; j++) {

        if (canClaimEtherGrassTokenId(_tokenId) && mintedSoFar < _count) {
          _egTokenIdsUsed[_tokenId] = _egTokenIdsUsed[_tokenId] + 1;
          _egOwnerMintCount.increment();
          mintedSoFar += 1;
          _mintAnElement(_to);
        }
      }
    }
  }

  function totalMint() public view returns (uint256) {
    return _totalSupply();
  }

  function totalEtherGrassMint() public view returns (uint256) {
    return _egTokenSupply();
  }

  function price(uint256 _count) public view returns (uint256) {
    return _price.mul(_count);
  }

  function walletOfOwner(address _owner) external view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);
    uint256[] memory tokensId = new uint256[](tokenCount);
    for (uint256 i = 0; i < tokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokensId;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function canClaimEtherGrassTokenId(uint256 _tokenId) public view returns (bool) {
    return _egTokenIdsUsed[_tokenId] < EG_MINTS_PER_ID;
  }

  function mintsUsedForTokenId(uint256 _tokenId) public view returns (uint256) {
    return _egTokenIdsUsed[_tokenId];
  }

  function etherGrassIdsOwned(address _address) external view returns (uint256[] memory) {
    return EtherGrassOwners.etherGrassIdsOwned(_address);
  }

  function etherGrassIdsClaimable(address _address) external view returns (uint256[] memory) {
    return EtherGrassOwners.etherGrassIdsClaimable(_address, EG_MINTS_PER_ID, _egTokenIdsUsed);
  }

  function etherGrassMintsClaimable(address _address) public view returns (uint256) {
    return EtherGrassOwners.etherGrassMintsClaimable(_address, EG_MINTS_PER_ID, _egTokenIdsUsed);
  }

  function etherGrassMintingAllowed() public view returns (bool) {
    return _eg_minting_allowed;
  }

  function publicMintingAllowed() public view returns (bool) {
    return _public_minting_allowed;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension)) : "";
  }

  // onlyOwner

  function setBaseURI(string memory baseURI) public onlyOwner {
    baseTokenURI = baseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) external onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool val) public onlyOwner {
    if (val == true) {
      _pause();
      return;
    }
    _unpause();
  }

  function withdrawAll() public payable onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0);
    _withdraw(CREATOR_ADDRESS, balance);
  }

  function reserve(uint256 _count) public onlyOwner {
    uint256 total = _totalSupply();
    require(total + _count <= MAX_ELEMENTS, "Not Enough");
    require(total <= MAX_ELEMENTS, "Sold Out");
    for (uint256 i = 0; i < _count; i++) {
      _mintAnElement(_msgSender());
    }
  }

  function setPrice(uint256 _newPrice) external onlyOwner {
    _price = _newPrice;
  }

  function setAllowEGMinting(bool _allow) external onlyOwner {
    _eg_minting_allowed = _allow;
  }

  function setAllowPublicMinting(bool _allow) external onlyOwner {
    _public_minting_allowed = _allow;
  }

  // private / internal

  function _totalSupply() internal view returns (uint) {
    return _tokenIds.current() - 1;
  }

  function _nextTokenId() internal view returns (uint) {
    return _tokenIds.current();
  }

  function _egTokenSupply() internal view returns (uint) {
    return _egOwnerMintCount.current();
  }

  function _mintAnElement(address _to) private {
    uint id = _nextTokenId();
    _tokenIds.increment();
    _safeMint(_to, id);
    emit CreateEtherGrassPFP(id);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function _withdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{value: _amount}("");
    require(success, "Transfer Failed");
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }
}
