// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

/**
* @dev Required interface of an ERC165 compliant contract, as defined in the
* https://eips.ethereum.org/EIPS/eip-165[EIP].
*   Note: the ERC-165 identifier for this interface is 0x01ffc9a7.
*/
interface IERC165 {
  // **************************************
  // *****            VIEW            *****
  // **************************************
    /// @dev Returns if a contract implements an interface.
    ///   Interface identification is specified in ERC-165. This function uses less than 30,000 gas.
    function supportsInterface(bytes4 interfaceId_) external view returns (bool);
  // **************************************
}
