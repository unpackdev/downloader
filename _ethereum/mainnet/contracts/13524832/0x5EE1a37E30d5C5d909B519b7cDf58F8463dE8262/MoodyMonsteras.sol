// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ERC721Pausable.sol";
import "./MoodyMonsterasVIPs.sol";

contract MoodyMonsteras is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;
  Counters.Counter private _vipTokenCount;

  uint256 private _price = 2.9 * 10**16;

  uint256 public constant MAX_ELEMENTS = 2900;
  uint256 public constant MAX_BY_MINT = 5;
  uint256 public constant MAX_VIP_MINTS = 50;
  address public constant CREATOR_ADDRESS = 0xc8799A6b6b78f3409A893bd8dd1f2399a9b05FCf;
  string public baseTokenURI;

  mapping (uint256 => uint256) private _vipTokenIdsUsed;
  mapping (uint => string) public moodyMonsteraNames;

  event CreateMonstera(uint256 indexed id);
  event MonsteraNameChange(address _by, uint _tokenId, string _name);

  constructor(string memory baseURI) ERC721("MoodyMonsteras", "MONSTERA") {
    setBaseURI(baseURI);
    pause(true);
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
    require(_totalSupply() + _count <= MAX_ELEMENTS, "Not Enough Left");
    require(_totalSupply() <= MAX_ELEMENTS, "Sold Out");
    require(_count <= MAX_BY_MINT, "Too Many");
    require(msg.value >= price(_count), "Below Price");

    for (uint256 i = 0; i < _count; i++) {
      _mintAnElement(_to);
    }
  }

  function vipMint(address _to, uint256[] memory _tokensId) public payable saleIsOpen {
    require(MAX_VIP_MINTS.sub(_vipTokenSupply()) > 0, "VIP Mints Out");
    require(_tokensId.length <= MAX_VIP_MINTS.sub(_vipTokenSupply()), "Not Enough VIP Mints");
    require(_totalSupply() + _tokensId.length <= MAX_ELEMENTS, "Not Enough Left");
    require(_totalSupply() <= MAX_ELEMENTS, "Sold Out");

    for (uint256 i = 0; i < _tokensId.length; i++) {
      uint256  _tokenId = _tokensId[i];
      require(MoodyMonsterasVIPs.isVipToken(_tokenId), "Token Not VIP");
      require(canClaimVIPTokenId(_tokenId), "VIP Token Claimed");
      require(MoodyMonsterasVIPs.ownsToken(_msgSender(), _tokenId), "Unowned Token");
      _vipTokenIdsUsed[_tokenId] = 1;
      _vipTokenCount.increment();
      _mintAnElement(_to);
    }
  }

  function totalMint() public view returns (uint256) {
    return _totalSupply();
  }

  function totalVIPMint() public view returns (uint256) {
    return _vipTokenSupply();
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

  function changeName(uint _tokenId, string memory _name) public {
    require(ownerOf(_tokenId) == _msgSender(), "Not Owned");
    moodyMonsteraNames[_tokenId] = _name;
    emit MonsteraNameChange(_msgSender(), _tokenId, _name);
  }

  function viewName(uint _tokenId) external view returns( string memory ){
    require( _tokenId < totalSupply(), "Unknown Id" );
    return moodyMonsteraNames[_tokenId];
  }
    
  function namesOfOwner(address _owner) external view returns(string[] memory ) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
      return new string[](0);
    } else {
        string[] memory result = new string[](tokenCount);
      uint256 index;
      for (index = 0; index < tokenCount; index++) {
        result[index] = moodyMonsteraNames[ tokenOfOwnerByIndex(_owner, index) ];
      }
      return result;
    }
  }

  function canClaimVIPTokenId(uint256 _tokenId) public view returns (bool) {
    return _vipTokenIdsUsed[_tokenId] == 0;
  }

  function vipIdsOwned(address _address) external view returns (uint256[] memory) {
    return MoodyMonsterasVIPs.vipIdsOwned(_address);
  }

  function vipIdsClaimable(address _address) external view returns (uint256[] memory) {
    return MoodyMonsterasVIPs.vipIdsClaimable(_address, _vipTokenIdsUsed);
  }

  // onlyOwner

  function setBaseURI(string memory baseURI) public onlyOwner {
    baseTokenURI = baseURI;
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

  // private / internal

  function _totalSupply() internal view returns (uint) {
    return _tokenIds.current();
  }

  function _vipTokenSupply() internal view returns (uint) {
    return _vipTokenCount.current();
  }

  function _mintAnElement(address _to) private {
    uint id = _totalSupply();
    _tokenIds.increment();
    _safeMint(_to, id);
    emit CreateMonstera(id);
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
