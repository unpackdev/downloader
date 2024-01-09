
pragma solidity ^0.8.10;

interface IChubbyKaijuDAOStakingV1 {
  function stakeTokens(address, uint16[] calldata, bytes[] memory) external;
}