pragma solidity ^0.6.0;

interface ILinkOracle {

  function latestAnswer() external view returns (int256);
}
