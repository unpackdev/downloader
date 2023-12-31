// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

 /**
  * @dev Interface for the blocklist contract
  */
interface IBlocklist {
 /**
  * @dev Checks whether `operator` is blocked. Checks against both the operator address
  * along with the operator codehash
  * @param operator - Address of operator
  * @return Bool whether operator is blocked
  */
  function isBlocked(address operator) external view returns (bool);

 /**
  * @dev Checks whether `operator` is blocked.
  * @param operator - Address of operator
  * @return Bool whether operator is blocked
  */
  function isBlockedContractAddress(address operator) external view returns (bool);

 /**
  * @dev Checks whether `contractAddress` codehash is blocked.
  * @param contractAddress - Contract address
  * @return Bool whether code hash is allowed
  */
  function isBlockedCodeHash(address contractAddress) external view returns (bool);
}
