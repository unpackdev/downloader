// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Strings.sol";

interface iConatus {
  function prices() external view returns (uint256[] memory);

  function totalAmounts() external view returns (uint256[] memory);

  function mintedTokenAmounts() external view returns (uint256[] memory);

  function mintedTokenIdListForVendingMachine()
    external
    view
    returns (uint256[] memory);

  function tokenIds(address _owner) external view returns (uint256[] memory);

  function toTokenId(uint256 _type, uint256 edition)
    external
    view
    returns (uint256);

  function mint(uint256 _type) external payable;

  function mintForVendingMachine(address to, uint256 edition) external;

  function mintWithCard(uint256 _type) external;

  function setIsOnSale(bool isOnSale) external;

  function setIsMetadataFrozen(bool isMetadataFrozen) external;

  function setBaseTokenURI(string calldata newBaseURI) external;

  function withdraw() external;
}

contract Conatus is iConatus, ERC721, ReentrancyGuard, Ownable {
  uint256 private constant TYPE_NUM = 3;
  uint256 private constant SUPPLY_FOR_VENDING_MACHINE = 50;
  uint256[] private _prices = [1 ether, 0.5 ether, 0.5 ether];
  uint256[] private _totalAmounts = [3, 3, 5];
  uint256[] private _mintedAmounts = [0, 0, 0];
  uint256[] private _mintedTokenIdListForVendingMachine;

  uint256 private constant ONE_MILLION = 1_000_000;
  address public constant ARTIST = 0x16e7382fb65866de3A54Ad494885fd25A4Db42A8;

  bool public isOnSale;
  bool public isMetadataFrozen;

  string private _baseTokenURI;

  constructor(string memory baseTokenURI) ERC721("Conatus", "CONATUS") {
    _baseTokenURI = baseTokenURI;
  }

  modifier checkMintable(uint256 _type) {
    require(isOnSale, "Conatus: Not on sale");
    require(_type >= 1 && _type <= TYPE_NUM, "Conatus: Invalid type");
    _;
  }

  function prices() external view override returns (uint256[] memory) {
    uint256[] memory __prices = new uint256[](TYPE_NUM);
    __prices = _prices;
    return __prices;
  }

  function totalAmounts() external view override returns (uint256[] memory) {
    uint256[] memory __totalAmounts = new uint256[](TYPE_NUM);
    __totalAmounts = _totalAmounts;
    return __totalAmounts;
  }

  function mintedTokenAmounts()
    external
    view
    override
    returns (uint256[] memory)
  {
    uint256[] memory __mintedAmounts = new uint256[](TYPE_NUM);
    __mintedAmounts = _mintedAmounts;
    return __mintedAmounts;
  }

  function mintedTokenIdListForVendingMachine()
    external
    view
    override
    returns (uint256[] memory)
  {
    return _mintedTokenIdListForVendingMachine;
  }

  function toTokenId(uint256 _type, uint256 edition)
    public
    view
    override
    returns (uint256)
  {
    return _type * ONE_MILLION + edition;
  }

  function tokenIds(address _owner)
    external
    view
    override
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(_owner);
    uint256[] memory ids = new uint256[](tokenCount);
    uint256 count;
    for (uint256 _type = 1; _type <= TYPE_NUM; _type++) {
      for (
        uint256 edition = 1;
        edition <= _totalAmounts[_type - 1];
        edition++
      ) {
        uint256 tokenId = toTokenId(_type, edition);
        if (_exists(tokenId) && ownerOf(tokenId) == _owner) {
          ids[count] = tokenId;
          count++;
        }
      }
    }
    for (
      uint256 edition = 1;
      edition <= SUPPLY_FOR_VENDING_MACHINE;
      edition++
    ) {
      uint256 tokenId = toTokenId(4, edition);
      if (_exists(tokenId) && ownerOf(tokenId) == _owner) {
        ids[count] = tokenId;
        count++;
      }
    }
    return ids;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(_exists(tokenId), "Conatus: URI query for nonexistent token");
    return
      string(
        bytes.concat(
          bytes(_baseTokenURI),
          bytes(Strings.toString(tokenId)),
          bytes(".json")
        )
      );
  }

  function mint(uint256 _type)
    external
    payable
    override
    nonReentrant
    checkMintable(_type)
  {
    require(msg.value == _prices[_type - 1], "Conatus: Invalid price");
    doMint(_msgSender(), _type);
  }

  function mintForVendingMachine(address to, uint256 edition)
    external
    override
    onlyOwner
  {
    require(
      edition >= 1 && edition <= SUPPLY_FOR_VENDING_MACHINE,
      "Conatus: Invalid edition"
    );
    uint256 tokenId = toTokenId(4, edition);
    mintAndTransfer(to, tokenId);
    _mintedTokenIdListForVendingMachine.push(tokenId);
  }

  function mintWithCard(uint256 _type)
    external
    override
    onlyOwner
    checkMintable(_type)
  {
    doMint(owner(), _type);
  }

  function setIsOnSale(bool _isOnSale) external override onlyOwner {
    isOnSale = _isOnSale;
  }

  function setIsMetadataFrozen(bool _isMetadataFrozen)
    external
    override
    onlyOwner
  {
    require(!isMetadataFrozen, "Conatus: isMetadataFrozen cannot be changed");
    isMetadataFrozen = _isMetadataFrozen;
  }

  function setBaseTokenURI(string memory baseTokenURI) external onlyOwner {
    require(!isMetadataFrozen, "Conatus: Metadata is already frozen");
    _baseTokenURI = baseTokenURI;
  }

  function withdraw() external override onlyOwner {
    Address.sendValue(payable(msg.sender), address(this).balance);
  }

  function doMint(address to, uint256 _type) internal {
    uint256 index = _type - 1;
    require(_mintedAmounts[index] < _totalAmounts[index], "Conatus: Sold out");

    uint256 tokenId = toTokenId(_type, _mintedAmounts[index] + 1);
    mintAndTransfer(to, tokenId);
    _mintedAmounts[index]++;
  }

  function mintAndTransfer(address to, uint256 tokenId) internal {
    _safeMint(ARTIST, tokenId);
    _safeTransfer(ARTIST, to, tokenId, "");
  }
}
