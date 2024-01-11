// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "./ACLAuth.sol";

abstract contract AbstractSweethearts is ACLAuth {
  mapping(address => bool) public sweethearts;

  event SweetheartUpdated(address sweetheart, bool isSweeheart);

  /**
   * @notice Toggles an address as Sweetheart (partner addresses that don't pay a redemption fee)
   * @param _sweetheart The address that shall become/lose their sweetheart status
   */
  function updateSweetheart(address _sweetheart, bool _enabled) external onlyRoles(DAO_ROLE, GUARDIAN_ROLE) {
    sweethearts[_sweetheart] = _enabled;
    emit SweetheartUpdated(_sweetheart, _enabled);
  }
}
