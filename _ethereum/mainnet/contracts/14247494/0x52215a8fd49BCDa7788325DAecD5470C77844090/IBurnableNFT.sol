// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IBurnableNFT {
  function fBurn(uint256 _pId) external; /* onlyRole(BURNER_ROLE) || NFT owner */

  function fBulkBurn(uint256 _pFromId, uint256 _pToId) external; /* onlyRole(BURNER_ROLE) */
}
