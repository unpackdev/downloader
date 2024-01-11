pragma solidity ^0.8.10;


interface IVamirToken {
  function burn(address from, uint256 amount) external;
  function balanceOf(address owner) external view returns(uint256);
  function allowance(address owner, address spender) external view returns(uint256);
}