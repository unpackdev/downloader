// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

/**
 * @dev Required interface for https://eips.ethereum.org/EIPS/eip-2309[ERC2309], A standardized event emitted 
 * when creating/transferring one, or many non-fungible tokens using consecutive token identifiers.
 */
contract IERC2309 {
    /**
     * @dev EIP-2309 event to use during minting.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed fromAddress, address indexed toAddress);
}
