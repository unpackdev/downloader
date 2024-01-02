// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

// import "./IERC165.sol";

/**
* @dev Required interface of an ERC173 compliant contract, as defined in the
* https://eips.ethereum.org/EIPS/eip-173[EIP].
*   Note: the ERC-165 identifier for this interface is 0x7f5828d0.
*/
interface IERC173 /* is IERC165 */ {
  // **************************************
  // *****           ERRORS           *****
  // **************************************
    /// @dev Thrown when `operator` is not the contract owner.
    /// 
    /// @param operator address trying to use a function reserved to contract owner without authorization
    error IERC173_NOT_OWNER(address operator);
  // **************************************

  // **************************************
  // *****           EVENTS           *****
  // **************************************
    /// @dev This emits when ownership of a contract changes.
    /// 
    /// @param previousOwner the previous contract owner
    /// @param newOwner the new contract owner
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  // **************************************

  // **************************************
  // *****       CONTRACT_OWNER       *****
  // **************************************
    /// @dev Set the address of the new owner of the contract.
    ///   Set `newOwner_` to address(0) to renounce any ownership.
    function transferOwnership(address newOwner_) external; 
  // **************************************

  // **************************************
  // *****            VIEW            *****
  // **************************************
    /// @dev Returns the address of the owner.
    function owner() external view returns(address);
  // **************************************
}
