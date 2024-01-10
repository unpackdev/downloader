// SPDX-License-Identifier: MIT

pragma solidity = 0.8.7;

import "./IERC20.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./Context.sol";
import "./Ownable.sol";

contract Reserve is Ownable {

  using SafeERC20 for IERC20;

  IERC20 public token;

  uint256 private reserve;
  uint256 private maxReserve;
  uint256 public gasCost;
  bool private initialized = false;

  mapping (uint256 => bool) public processed;

  event Minted(address to, uint256 amount);
  event Burned(address from, uint256 amount);
  
  constructor(IERC20 _token) {
    token = _token;
  }

  function initialize() external onlyOwner {
    require(initialized == false, "already initialized");
    reserve = token.balanceOf(address(this));
    maxReserve = token.totalSupply() / 2;
    require(reserve <= maxReserve, "invalid reserve status");
    initialized = true;
  }

  function setGasCost(uint256 _gasCost) external onlyOwner {
    gasCost = _gasCost;
  }

  function mint(address to, uint256 _amount, uint256 nonce) external onlyOwner {
    require(_amount != 0, "amount is zero");
    require(processed[nonce] == false, "already processed");
    require(reserve >= _amount, "amount can't be bigger than reserve");
    token.safeTransfer(to, _amount);
    reserve = reserve - _amount;
    processed[nonce] = true;
    emit Minted(to, _amount);
  }

  function burn(uint256 _amount) external payable {
    require(_amount != 0, "amount is zero");
    require(msg.value > gasCost, "gas is insufficient");
    payable(owner()).transfer(msg.value);
    token.safeTransferFrom(msg.sender, address(this), _amount);
    reserve = reserve + _amount;
    require(reserve <= maxReserve, "invalid reserve status");
    emit Burned(msg.sender, _amount);
  }

  function withdrawFreeToken(uint256 _amount) external onlyOwner {
    uint256 bal = token.balanceOf(address(this));
    uint256 free = bal - reserve;
    require(free > 0, "No available token to withdraw");
    token.safeTransfer(msg.sender, _amount);
  }

  function withdrawDust(uint256 _amount) external onlyOwner {
    payable(msg.sender).transfer(_amount);
  }
}