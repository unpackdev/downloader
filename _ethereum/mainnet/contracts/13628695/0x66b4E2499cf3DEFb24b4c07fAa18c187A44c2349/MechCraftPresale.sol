// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./Ownable.sol";

contract MechCraftPresale is Ownable {  
  using SafeERC20 for IERC20;

  address public token0;
  address public token1;

  uint256 public token0Price = 0;
  uint256 public token1Price = 0;
  uint256 public price = 0;
  
  mapping(address => uint256) private chestQty;
  
  // constructor(address _token0, address _token1) {
  //   token0 = _token0;
  //   token1 = _token1;
  // }

  function setToken(address _token0, address _token1) external onlyOwner {
    token0 = _token0;
    token1 = _token1;
  }

  function setPrice(uint256 _price, uint256 _token0Price, uint256 _token1Price) external onlyOwner {
    price = _price;
    token0Price = _token0Price;
    token1Price = _token1Price;
  }

  function buyChestWithT0(uint256 _amount) external returns (uint256) {
    require(_amount >= token0Price, "Insufficient payment");

    IERC20(token0).safeTransferFrom(msg.sender, owner(), _amount);
    chestQty[msg.sender]++;
    return chestQty[msg.sender];
  }

  function buyChestWithT1(uint256 _amount) external returns (uint256) {
    require(_amount >= token1Price, "Insufficient payment");

    IERC20(token1).safeTransferFrom(msg.sender, owner(), _amount);
    chestQty[msg.sender]++;
    return chestQty[msg.sender];
  }

  function buyChest() external payable returns (uint256) {
    require(msg.value >= price, "Insufficient payment");

    payable(owner()).transfer(address(this).balance);
    chestQty[msg.sender]++;
    return chestQty[msg.sender];
  }

  function redeemChest() external returns (uint256) {
    require(chestQty[msg.sender] > 0, "Insufficient balance");

    chestQty[msg.sender]--;
    return chestQty[msg.sender];
  }

  function redeemChestCustomQty(uint256 _qty) external returns (uint256) {
    require(chestQty[msg.sender] >= _qty, "Insufficient balance");

    chestQty[msg.sender] -= _qty;
    return chestQty[msg.sender];
  }
  
  function chestQtyOf(address _account) external view returns (uint256) {
    return chestQty[_account];
  }
  
  function getMyChestQty() external view returns (uint256) {
    return chestQty[msg.sender];
  }

  function withdrawToken(IERC20 _token) external onlyOwner {
    uint256 tokenBalance = _token.balanceOf(address(this));
    require(tokenBalance > 0, "Insufficient balance");
    _token.safeTransfer(msg.sender, tokenBalance);
  }
    
  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  function getTokenBalance(address _tokenAddress) external onlyOwner view returns (uint256) {
    IERC20 token = IERC20(_tokenAddress);
    return token.balanceOf(address(this));
  }

  function getBalance() external onlyOwner view returns (uint256) {
    return address(this).balance;
  }
}
