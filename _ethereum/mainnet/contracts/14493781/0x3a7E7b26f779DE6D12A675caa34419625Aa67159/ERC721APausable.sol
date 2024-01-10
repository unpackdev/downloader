pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./Pausable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721APausable is ERC721A, Pausable {
    /**
     * @dev See {ERC721A-_beforeTokenTransfers}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfers(
          address from,
          address to,
          uint256 startTokenId,
          uint256 quantity
      ) internal override virtual {
      super._beforeTokenTransfers(from, to, startTokenId, quantity);
      require(!paused(), "ContractPaused");
    }
}
