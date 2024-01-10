// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

interface IMintAndBond {

  function mintAndBond721(
    uint256 vaultId,
    uint256[] calldata ids,
    uint256 bondId,
    address to,
    uint256 maxPrice
  ) external returns (uint256);
  function claim(address _user, uint256[] memory _indexes, address _vault) external returns (uint256);
  function pendingFor(address _user, uint256 _index, address _vault) external view returns (uint256, bool);
  function setTimelock(uint48 _timelock) external;
  function rescue(address _token) external;
}
