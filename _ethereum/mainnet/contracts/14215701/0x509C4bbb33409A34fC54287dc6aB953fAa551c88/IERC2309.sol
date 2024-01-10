// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IERC721.sol";

interface IERC2309 is IERC721 {
  /**
    @notice This event is emitted when ownership of a consecutive batch of tokens changes by any mechanism.
    This includes minting, transferring, and burning.

    @dev The address executing the transaction MUST own all the tokens within the range of
    fromTokenId and toTokenId, or MUST be an approved operator to act on the owners behalf.
    The fromTokenId and toTokenId MUST be a consecutive range of tokens IDs.
    When minting/creating tokens, the `fromAddress` argument MUST be set to `0x0` (i.e. zero address).
    When burning/destroying tokens, the `toAddress` argument MUST be set to `0x0` (i.e. zero address).

    @param fromTokenId The token ID that begins the batch of tokens being transferred
    @param toTokenId The token ID that ends the batch of tokens being transferred
    @param fromAddress The address transferring ownership of the specified range of tokens
    @param toAddress The address receiving ownership of the specified range of tokens.
  */
  event ConsecutiveTransfer(uint indexed fromTokenId, uint toTokenId, address indexed fromAddress, address indexed toAddress);
}
