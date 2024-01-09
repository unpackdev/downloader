// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Enumerable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IMineableWords is IERC721Enumerable {
  /**
   * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
   * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
   */
  function decodeMword(uint88 encoded) external view returns (string memory);
}
