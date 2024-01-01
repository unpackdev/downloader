// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./ERC2981.sol";
import "./ERC1155.sol";

abstract contract ERC1155Royalty is ERC1155, ERC2981 {
  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function feeDenominator() public pure returns (uint96) {
    return _feeDenominator();
  }

  function _burn(address from, uint256 id, uint256 amount) internal virtual override(ERC1155) {
    super._burn(from, id, amount);
    _resetTokenRoyalty(id);
  }
}
