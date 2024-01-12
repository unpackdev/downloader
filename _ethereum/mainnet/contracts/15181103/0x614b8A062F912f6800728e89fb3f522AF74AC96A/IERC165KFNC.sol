// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;


/// @title Interface of the ERC165 standard, as defined in the
///     https://eips.ethereum.org/EIPS/eip-165[EIP].
/// @author Kfish n Chips
/// @dev Implementers can declare support of contract interfaces, which can then be
///     queried by others ({ERC165Checker}).
/// @custom:security-contact security@kfishnchips.com
interface IERC165KFNC {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}
