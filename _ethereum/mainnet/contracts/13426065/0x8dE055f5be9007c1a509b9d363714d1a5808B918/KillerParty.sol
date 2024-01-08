// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";

contract KillerParty is ERC721Enumerable, Ownable {
  using SafeMath for uint256;
  using Counters for Counters.Counter;
  
  uint256 public constant RESERVE = 13;
  uint256 public constant MAX_ELEMENTS = 1001;
  uint256 public constant MAX_PURCHASE = 33;

  uint256 public PRICE = 0.03 ether;
  bool public locked = false;

  Counters.Counter private _tokenIds;
  
  mapping(uint256 => Killer) _killers;
  mapping(string => uint8) _seedToKillers;

  uint256 private startingBlockNumber = 0;
  bool private PAUSE = false;

  address public constant potAddress = 0x3647F724DfF26117E1daa234787b0CE1d96D4285;
  address public constant devAddress = 0x1B930f5F02DBf357A750E951Eb6D8b9d768FB14B;
  
  string public baseTokenURI;

  event PauseEvent(bool pause);
  event WelcomeToKillerParty(uint256 indexed id, Killer killer);

  struct Killer {
    uint bg;
    uint glove;
    uint jacket;
    uint hilt;
    uint blade;
    uint vine;
    uint pumpkin;
    uint face;
    uint accessory;
  }

  constructor(string memory _defaultBaseURI) ERC721("KillerParty", "KLLR") {
    setBaseURI(_defaultBaseURI);

    startingBlockNumber = block.number;
  }

  /**
  * @dev Throws if the contract is already locked
  */
  modifier notLocked() {
    require(!locked, "Contract already locked.");
    _;
  }

  modifier saleIsOpen {
    require(_totalSupply() <= MAX_ELEMENTS, "Soldout!");
    require(!PAUSE, "Sales not open");
    _;
  }

  function setBaseURI(string memory _baseTokenURI) public onlyOwner notLocked {
    baseTokenURI = _baseTokenURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  /**
  * @dev Returns the tokenURI if exists
  * See {IERC721Metadata-tokenURI} for more details.
  */
  function tokenURI(uint256 _tokenId) public view virtual override(ERC721) returns (string memory) {
    return getTokenURI(_tokenId);
  }

  function getTokenURI(uint256 _tokenId) public view returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    string memory base = baseTokenURI;

    if (_tokenId > _totalSupply()) {
      return bytes(base).length > 0 ? string( abi.encodePacked(base, "0.json") ) : "";
    }

    return bytes(base).length > 0 ? string( abi.encodePacked(base, uintToString(_tokenId), ".json") ) : "";
  }

  function _totalSupply() internal view returns (uint) {
    return _tokenIds.current();
  }

  function totalMint() public view returns (uint256) {
    return _totalSupply();
  }

  function mint(uint _count) public payable saleIsOpen {
    // Require hash not assigned
    // require(_hashes[_hash] != 1);
    require(_totalSupply() + _count <= MAX_ELEMENTS - RESERVE, "Max limit reached");
    require(_count <= MAX_PURCHASE, "Max purchase limit");
    require(msg.value >= price(_count), "Value below price");

    for (uint i = 0; i < _count; i++) {
      _tokenIds.increment();
      uint256 _id = _tokenIds.current();

      _safeMint(msg.sender, _id);

      Killer memory killer = _generateKiller(_id);
      _killers[_id] = killer;

      string memory seed = _getKillerSeed(killer);
      _seedToKillers[seed] = 1;

      emit WelcomeToKillerParty(_id, killer);
    }
  }

  function _getKillerSeed(Killer memory _killer) internal pure returns (string memory seed) {
    return string(abi.encodePacked(uintToString(_killer.bg), uintToString(_killer.glove), uintToString(_killer.jacket), uintToString(_killer.hilt), uintToString(_killer.blade), uintToString(_killer.vine), uintToString(_killer.pumpkin), uintToString(_killer.face), uintToString(_killer.accessory)));
  }

  function _generateKiller(uint256 _id) internal view returns (Killer memory killer) {
    Killer memory k = Killer(
      block.number * _id % 3,
      (block.number + _id) % 3,
      block.number * _id % 6,
      (block.number - _id) % 3,
      block.number * _id % 3,
      (block.number * _id + _id) % 3,
      block.number * _id % 7,
      block.number * _id % 24,
      (block.number + (startingBlockNumber * _id)) % 2
    );

    string memory seed = _getKillerSeed(k);

    if (_seedToKillers[seed] == 1) {
      return _generateKiller(_id + 1);
    }

    return k;
  }

  function getKiller(uint256 _id) public view returns (Killer memory killer) {
    return _killers[_id];
  }

  function _uint2str(uint _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
        return "0";
    }
    uint j = _i;
    uint len;
    while (j != 0) {
        len++;
        j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len;
    while (_i != 0) {
        k = k-1;
        uint8 temp = (48 + uint8(_i - _i / 10 * 10));
        bytes1 b1 = bytes1(temp);
        bstr[k] = b1;
        _i /= 10;
    }
    return string(bstr);
  }

  function burn(uint256 tokenId) public virtual {
      //solhint-disable-next-line max-line-length
      require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
      _burn(tokenId);
  }

  function price(uint256 _count) public view returns (uint256) {
    return PRICE.mul(_count);
  }

  function setPause(bool _pause) public onlyOwner {
    PAUSE = _pause;
    emit PauseEvent(PAUSE);
  }

  /**
  * Reserve Killers for future activities and for supporters
  */
  function reserveKillers() public onlyOwner {
    uint i;
    for (i = 0; i < RESERVE; i++) {
        _tokenIds.increment();
        uint256 _id = _tokenIds.current();

        _safeMint(msg.sender, _id + i);
    }
  }

  /**
  * @dev Sets the prices for minting - in case of cataclysmic ETH price movements
  */
  function setPrice(uint256 _price) external onlyOwner notLocked {
    require(_price > 0, "Invalid prices.");
    PRICE = _price;
  }

  function withdrawAll() public onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0);
    _widthdraw(potAddress, balance.mul(50).div(100));
    _widthdraw(devAddress, address(this).balance);
  }

  function _widthdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{value: _amount}("");
    require(success, "Transfer failed.");
  }

  /**
  * @dev locks the contract (prevents changing the metadata base uris)
  */
  function lock() public onlyOwner notLocked {
    require(bytes(baseTokenURI).length > 0, "Thou shall not lock prematurely!");
    require(totalSupply() == MAX_ELEMENTS, "Not all Killers are minted yet!");
    locked = true;
  }

  function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
    uint8 i = 0;
    while(i < 32 && _bytes32[i] != 0) {
        i++;
    }
    bytes memory bytesArray = new bytes(i);
    for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
        bytesArray[i] = _bytes32[i];
    }
    return string(bytesArray);
  }

  function uintToBytes(uint v) pure private returns (bytes32 ret) {
    if (v == 0) {
        ret = '0';
    }
    else {
        while (v > 0) {
            ret = bytes32(uint(ret) / (2 ** 8));
            ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
            v /= 10;
        }
    }
    return ret;
  }

  function uintToString(uint v) pure private returns (string memory ret) {
    return bytes32ToString(uintToBytes(v));
  }

  /**
  * @dev Do not allow renouncing ownership
  */
  function renounceOwnership() public override(Ownable) onlyOwner {}
}
