// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/**
 * @dev IERC2309 interface
 * See: https://eips.ethereum.org/EIPS/eip-2309 for more details
 */
interface IERC2309 {
    /**
     * @dev Emitted when one or multiple tokens in the range `fromTokenId` to `toTokenId` are transferred from `fromAddress` to `toAddress`.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed fromAddress, address indexed toAddress);

}