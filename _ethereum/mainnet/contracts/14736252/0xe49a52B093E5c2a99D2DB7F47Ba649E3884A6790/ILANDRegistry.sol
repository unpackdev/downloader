//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

interface ILANDRegistry {
  /**
   * @notice Set LAND updateOperator
   * @param assetId - LAND id
   * @param operator - address of the account to be set as the updateOperator
   */
  function setUpdateOperator(uint256 assetId, address operator) external;

  // getter for updateOperator
  function updateOperator(uint256) external view returns (address);
}
