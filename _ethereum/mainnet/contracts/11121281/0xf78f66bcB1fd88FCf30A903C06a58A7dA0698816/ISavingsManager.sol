// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.7.0;

interface ISavingsManager {
  function lastCollection(address _mAsset) external view returns (uint256);
  function lastPeriodStart(address _mAsset) external view returns (uint256);
  function periodYield(address _mAsset) external view returns (uint256);
  function savingsContract(address _mAsset) external view returns (address);
  function withdrawUnallocatedInterest(address _mAsset, address _recipient) external;
  function collectAndDistributeInterest(address _mAsset) external;
}
