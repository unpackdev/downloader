// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./ERC721A.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract UndeadTown is ERC721A, ERC2981, Ownable, ReentrancyGuard {
  // Collection info
  string private _baseTokenURI;
  uint256 public supply = 10000;
  uint256 public reservedSupply = 500;
  uint256 public publicSupply = supply - reservedSupply;

  uint256 public maxPerTx = 2;
  uint256 public maxPerTxDeadList = 4;

  // Utils
  bool public isActive;
  mapping(address => bool) private hasMinted;
  mapping(address => bool) private deadList;

  // Constructor
  constructor(string memory _uri) ERC721A("UndeadTown", "UndeadTown") {
    _baseTokenURI = _uri;
    ownerExhume(1);
  }

  // Owner mint
  function ownerExhume(uint256 _amount) public nonReentrant onlyOwner {
    require(reservedSupply > 0, "Sold out");
    require(reservedSupply - _amount >= 0, "Not enough available");
    reservedSupply -= _amount;
    _mint(msg.sender, _amount);
  }

  // Mint
  function exhume() public nonReentrant {
    uint256 _amount = getAmount();
    require(tx.origin == msg.sender, "Smart contract interactions disabled");
    require(isActive, "Closed");
    require(_amount > 0, "Sold out");
    require(!hasMinted[msg.sender], "Only one tx available");

    hasMinted[msg.sender] = true;
    publicSupply -= _amount;
    _mint(msg.sender, _amount);
  }

  // Deadlist
  function addToDeadList(address[] calldata addressList) external onlyOwner {
    for (uint256 i = 0; i < addressList.length; ++i) {
      deadList[addressList[i]] = true;
    }
  }

  // Getters
  function _baseURI() internal view override returns (string memory) {
    return _baseTokenURI;
  }

  function tokenExists(uint256 _id) public view returns (bool) {
    return _exists(_id);
  }

  function getHasMinted(address _address) external view returns (bool) {
    return hasMinted[_address];
  }

  function getIsInDeadList(address _address) external view returns (bool) {
    return deadList[_address];
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  // Setters
  function setBaseURI(string memory _uri) external onlyOwner {
    _baseTokenURI = _uri;
  }

  function toggleActive() external onlyOwner {
    isActive = !isActive;
  }

  function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  // Private
  function getAmount() private view returns (uint256) {
    if (deadList[msg.sender]) {
      return min(maxPerTxDeadList, publicSupply);
    } else {
      return min(maxPerTx, publicSupply);
    }
  }

  function min(uint256 a, uint256 b) private pure returns (uint256) {
    if (a <= b) {
      return a;
    } else {
      return b;
    }
  }
}
