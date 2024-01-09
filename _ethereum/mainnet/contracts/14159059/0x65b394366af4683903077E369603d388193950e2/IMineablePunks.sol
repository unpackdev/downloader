// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Enumerable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IMineablePunks is IERC721Enumerable {
  /**
   * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
   * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
   */
  function punkIdToAssets(uint256 mpunk) external view returns (uint96 assets);
}
