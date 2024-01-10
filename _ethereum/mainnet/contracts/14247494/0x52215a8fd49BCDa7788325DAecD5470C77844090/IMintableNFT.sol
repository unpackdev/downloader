// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IMintableNFT {
  function fMint(address _pTo, uint256 _pId) external; /* onlyRole(MINTER_ROLE) */

  function fBulkMint(
    address _pTo,
    uint256 _pFromId,
    uint256 _pToId
  ) external; /* onlyRole(MINTER_ROLE) */
}
