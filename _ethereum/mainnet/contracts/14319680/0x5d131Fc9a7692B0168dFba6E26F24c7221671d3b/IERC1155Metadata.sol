// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface for ERC1155Metadata as defined in the EIP
 */
interface IERC1155Metadata {
    /**
     * @dev ERC1155 token metadata functions
     */
    function uri(uint256 _id) external view returns (string memory);
}
