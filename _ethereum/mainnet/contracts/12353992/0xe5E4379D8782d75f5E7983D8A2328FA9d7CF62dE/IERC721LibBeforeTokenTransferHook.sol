// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Lib.sol";

/**
 * @dev Interface that can be used to hook additional beforeTokenTransfer functions into ERC721Lib
 */
interface IERC721LibBeforeTokenTransferHook {

   /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransferHook(bytes32 storagePosition, address from, address to, uint256 tokenId) external;

}