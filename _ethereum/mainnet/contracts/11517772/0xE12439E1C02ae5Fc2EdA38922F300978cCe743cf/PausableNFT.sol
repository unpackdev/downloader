// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./NFT.sol";
import "./Pausable.sol";

/**
 * @dev NFT with pausable token transfers and minting

 */
abstract contract PausableNFT is NFT, Pausable {
  /**
   * @dev Based on {ERC1155-_beforeTokenTransfer}.
   *
   * Requirements:
   *
   * - the contract must not be paused.
   */
  function _beforeTokenTransfer() internal virtual override {
    require(!paused(), 'PausableNFT: token transfer while paused');
  }
}
