// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IMaviaCreator {
  /**
   * @dev Gets the creator of the token
   * @param _id ID of the token
   * @return Address of the creator
   */
  function fGetCreator(uint256 _id) external view returns (address);

  /**
   * @dev Sets the creator of the token
   * @param _id ID of the token
   * @param _creator Address of the creator for the token
   */
  function fSetCreator(uint256 _id, address _creator) external;
}
