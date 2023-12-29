// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard
 */
interface ERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
