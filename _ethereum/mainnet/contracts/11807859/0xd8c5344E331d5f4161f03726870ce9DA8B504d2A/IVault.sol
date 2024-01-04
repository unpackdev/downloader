pragma solidity ^0.5.15;

interface IVault {
  function token() external view returns (address);
  function deposit(uint _amount) external;
}