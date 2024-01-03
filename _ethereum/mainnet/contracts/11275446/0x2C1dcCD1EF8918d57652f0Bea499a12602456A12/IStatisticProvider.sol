pragma solidity ^0.6.0;

interface IStatisticProvider {
  function current() external view returns (uint statistic);
}
