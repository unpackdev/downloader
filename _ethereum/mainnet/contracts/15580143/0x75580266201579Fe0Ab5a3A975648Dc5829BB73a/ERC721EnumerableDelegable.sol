// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721Delegable.sol";

/**
 * @title ERC721EnumerableDelegable
 * @dev Required interface of an ERC721RQ compliant contract.
 * @author 0xAnimist (kanon.art)
 */
abstract contract ERC721EnumerableDelegable is ERC721Enumerable, ERC721Delegable {

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Delegable, ERC721Enumerable) returns (bool) {
      return
        interfaceId == type(IERC721Delegable).interfaceId
        || interfaceId == type(IERC721Enumerable).interfaceId//TODO: REMOVE?
        || super.supportsInterface(interfaceId);
  }


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
  function _beforeTokenTransfer(
      address from,
      address to,
      uint256 tokenId
  ) internal virtual override(ERC721, ERC721Enumerable) {
      super._beforeTokenTransfer(from, to, tokenId);
  }

  function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721Delegable) {
    super._burn(tokenId);
  }

}
