// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;

interface IChiGasToken {
  function allowance(address owner, address spender) external view returns(uint256);
  function approve(address spender, uint256 amount) external returns(bool);
  function balanceOf(address account) external view returns (uint256);
  function computeAddress2(uint256 salt) external view returns(address);
  function decimals() external view returns(uint8);
  function free(uint256 value) external returns(uint256);
  function freeFrom(address from, uint256 value) external returns(uint256);
  function freeFromUpTo(address from, uint256 value) external returns(uint256);
  function freeUpTo(uint256 value ) external returns(uint256);
  function mint(uint256 value) external;
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function totalBurned() external view returns(uint256);
  function totalMinted() external view returns(uint256);
  function totalSupply() external view returns(uint256);
  function transfer(address recipient, uint256 amount) external returns(bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
}