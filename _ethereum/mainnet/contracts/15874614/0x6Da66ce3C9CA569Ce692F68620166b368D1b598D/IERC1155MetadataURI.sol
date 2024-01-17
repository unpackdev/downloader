// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155METADATAURI.sol)

pragma solidity 0.8.9;

interface IERC1155MetadataURI {
    function uri(uint256 id) external view returns (string memory);
}
