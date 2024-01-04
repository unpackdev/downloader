pragma solidity ^0.5.15;

interface IConverter {
  function convert(address) external returns (uint256);
}