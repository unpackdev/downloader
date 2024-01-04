pragma solidity 0.7.3;

interface IBFactory {
  function newBPool() external returns (address);
}