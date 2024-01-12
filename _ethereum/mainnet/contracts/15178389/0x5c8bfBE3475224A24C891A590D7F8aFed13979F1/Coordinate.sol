// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract Coordinate is ERC721A, Ownable, Pausable, ReentrancyGuard {
  using Strings for uint256;

  uint256 public constant maxSupply = 9393;
  uint256 public freeSupply = 393;
  uint256 public mocaSupply = 1000;
  uint256 public constant ethPrice = 0.06 ether;
  uint256 public constant mocaPrice = 330 * 10 ** 18;
  uint256 public freeMinted = 0;
  uint256 public mocaMinted = 0;
  bool public freeMintOpen = true;
  string private baseTokenURI;
  IERC20 public mocaToken;

  mapping(address => bool) private freeMinter;
  mapping(address => uint256) private freeMinterQuota;
  mapping(address => uint256) private freeClaimed;
  mapping(address => uint256) private mocaClaimed;

  constructor(IERC20 _mocaAddress)
    ERC721A("Project Coordinate", "COORDINATE")
  {
    mocaToken = _mocaAddress;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function _startTokenId()
    internal
    view
    virtual
    override(ERC721A)
    returns (uint256)
  {
    return 1;
  }

  function publicMint(uint256 _qty)
    external
    payable
    whenNotPaused
  {
    require(_totalMinted() + _qty <= maxSupply, "Would exceed maxSupply");
    require(msg.value == ethPrice * _qty, "Not enough ETH");
    _safeMint(msg.sender, _qty);
  }

  function publicMocaMint(uint256 _qty)
    external
    payable
    whenNotPaused
  {
    require(_totalMinted() + _qty <= maxSupply, "Would exceed maxSupply");
    require(mocaMinted + _qty <= mocaSupply, "Would exceed mocaSupply");
    mocaToken.transferFrom(msg.sender, address(this), mocaPrice * _qty);
    mocaClaimed[msg.sender] += _qty;
    mocaMinted += _qty;
    _safeMint(msg.sender, _qty);
  }

  function freeMint(uint256 _qty) external whenNotPaused {
    require(freeMintOpen, "Free mint is closed");
    require(_totalMinted() + _qty <= maxSupply, "Would exceed maxSupply");
    require(freeMinted + _qty <= freeSupply, "Would exceed freeSupply");
    require(freeMinterQuota[msg.sender] >= _qty, "Not enough quota");

    freeMinterQuota[msg.sender] -= _qty;
    freeClaimed[msg.sender] += _qty;
    freeMinted += _qty;
    _safeMint(msg.sender, _qty);
  }

  function freeMinterAdd(
    address[] calldata _addresses,
    uint256[] calldata _qtys
  )
    external
    onlyOwner
  {
    require(_addresses.length == _qtys.length, "Mismatch data length");
    for (uint256 i = 0; i < _addresses.length; i++) {
      require(_addresses[i] != address(0), "Can't set zero address");
      freeMinterQuota[_addresses[i]] = _qtys[i];
    }
  }

  function freeMinterRemove(address[] calldata _addresses) external onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
      require(_addresses[i] != address(0), "Can't set zero address");
      freeMinterQuota[_addresses[i]] = 0;
    }
  }

  function delegateFreeMintTo(
    address[] calldata _addresses,
    uint256[] calldata _qtys
  )
    external
    whenNotPaused
  {
    require(freeMinterQuota[msg.sender] > 0, "Zero quota");
    require(_addresses.length == _qtys.length, "Mismatch data length");

    // Get total delegate quantities
    uint256 totalDelegates = 0;
    for (uint256 i = 0; i < _qtys.length; i++) {
      totalDelegates += _qtys[i];
    }

    require(freeMinterQuota[msg.sender] >= totalDelegates, "Not enough quota");

    // Reduce msg.sender free mint quota
    freeMinterQuota[msg.sender] -= totalDelegates;

    for (uint256 i = 0; i < _addresses.length; i++) {
      /**
        * Add delegated quota to address without
        * resetting quota if address already exists
        */
      freeMinterQuota[_addresses[i]] = freeMinterQuota[_addresses[i]] > 0 ?
        freeMinterQuota[_addresses[i]] + _qtys[i] :
        _qtys[i];
    }
  }

  function freeMintQuotaOf(address _address) external view returns (uint256) {
    require(_address != address(0), "Zero address not found");
    return freeMinterQuota[_address];
  }

  function freeClaimedBy(address _address) external view returns (uint256) {
    require(_address != address(0), "Zero address not found");
    return freeClaimed[_address];
  }

  function setFreeSupply(uint256 _supply) external onlyOwner {
    freeSupply = _supply;
  }

  function setFreeMintOpen(bool _open) external onlyOwner {
    freeMintOpen = _open;
  }

  function mocaClaimedBy(address _address) external view returns (uint256) {
    require(_address != address(0), "Zero address not found");
    return mocaClaimed[_address];
  }

  function setMocaAddress(IERC20 _mocaAddress) external onlyOwner {
    mocaToken = _mocaAddress;
  }

  function setMocaSupply(uint256 _supply) external onlyOwner {
    mocaSupply = _supply;
  }
  
  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    baseTokenURI = baseURI;
  }

  function totalMinted() external view returns (uint256) {
    return _totalMinted();
  }

  function withdraw() external onlyOwner nonReentrant {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function withdrawMoca() external onlyOwner nonReentrant {
    mocaToken.transfer(msg.sender, mocaToken.balanceOf(address(this)));
  }
}
