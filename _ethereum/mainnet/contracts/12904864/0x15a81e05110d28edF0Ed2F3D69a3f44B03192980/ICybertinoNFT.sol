// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface ICybertinoNFT {
  /**
   * @dev Slightly different from TransferSingle event, emitted when `value`
   * tokens of token type `id` are minted to `to` by `operator` with platform's
   * nonce `nonce`.
   */
  event CybertinoMint(
    address indexed operator,
    address indexed to,
    uint256 id,
    uint256 value,
    uint256 indexed nonce
  );
}
