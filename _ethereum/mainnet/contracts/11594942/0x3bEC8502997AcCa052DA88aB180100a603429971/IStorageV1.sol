pragma solidity 0.6.12;

interface IStorageV1 {
  function getName() external view returns (string memory);

  function setName(string memory _name) external;

  function addPendingRewards(uint256 amount) external;
}
