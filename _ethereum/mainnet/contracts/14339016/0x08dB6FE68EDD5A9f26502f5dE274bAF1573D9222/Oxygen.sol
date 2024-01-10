// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.11;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IOxygen.sol";

contract Oxygen is IOxygen, ERC20, Ownable, ReentrancyGuard {
  mapping(address => bool) private admins;
  uint256 public MAX_SUPPLY;
  bool public tokenCapSet;
  uint256 public rewardCount;
  uint256 public donationCount;
  uint256 public taxCount;
  uint256 public mintedCount;
  uint256 public burnedCount;

  constructor() ERC20("Y2123 OXGN", "OXGN") {}

  function setMaxSupply(uint256 amount) external onlyOwner {
    require(amount > totalSupply(), "Value is smaller than the number of existing tokens");
    require(!tokenCapSet, "Token cap has been already set");

    MAX_SUPPLY = amount;
    tokenCapSet = true;
  }

  function addAdmin(address addr) external onlyOwner {
    require(addr != address(0), "empty address");
    admins[addr] = true;
  }

  function removeAdmin(address addr) external onlyOwner {
    require(addr != address(0), "empty address");
    admins[addr] = false;
  }

  function mint(address to, uint256 amount) external override nonReentrant {
    require(admins[msg.sender], "Only admins can mint");
    if (tokenCapSet) require(mintedCount + amount <= MAX_SUPPLY, "Amount exceeds max cap or max cap reached!");
    mintedCount = mintedCount + amount;
    _mint(to, amount);
  }

  function reward(address to, uint256 amount) external nonReentrant {
    require(admins[msg.sender], "Only admins can mint");
    if (tokenCapSet) {
      require(mintedCount + amount <= MAX_SUPPLY, "Amount exceeds max cap or max cap reached!");
      require(rewardCount + amount <= MAX_SUPPLY*2/5, "Amount exceeds 40% rewards pool!");
    }
    rewardCount = rewardCount + amount;
    mintedCount = mintedCount + amount;
    _mint(to, amount);
    //create 0.5 tokens for reserve
    if (tokenCapSet) _mint(address(this), amount/2);
  }

  function donate(address to, uint256 amount) external nonReentrant {
    require(admins[msg.sender], "Only admins can mint");
    if (tokenCapSet) require(mintedCount + amount <= MAX_SUPPLY, "Amount exceeds max cap or max cap reached!");
    donationCount = donationCount + amount;
    rewardCount = rewardCount + amount;
    mintedCount = mintedCount + amount;
    _mint(to, amount);
  }

  function tax(address to, uint256 amount) external nonReentrant {
    require(admins[msg.sender], "Only admins can mint");
    if (tokenCapSet) require(mintedCount + amount <= MAX_SUPPLY, "Amount exceeds max cap or max cap reached!");
    taxCount = taxCount + amount;
    rewardCount = rewardCount + amount;
    mintedCount = mintedCount + amount;
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) external override nonReentrant {
    require(admins[msg.sender], "Only admins can burn");
    burnedCount = burnedCount + amount;
    _burn(from, amount);
  }

  function withdrawReserve(address to, uint256 amount) external onlyOwner {
    require(amount <= balanceOf(address(this)), "amount exceeds balance");
    _transfer(address(this), to, amount);
  }

  function burnReserve(uint256 amount) external onlyOwner {
    require(amount <= balanceOf(address(this)), "amount exceeds balance");
    burnedCount = burnedCount + amount;
    _burn(address(this), amount);
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override(ERC20, IOxygen) returns (bool) {
    if (admins[_msgSender()]) {
      _transfer(sender, recipient, amount);
      return true;
    }
    return super.transferFrom(sender, recipient, amount);
  }
}
