//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./AccessControl.sol";
import "./ICitizenAlpha.sol";

/**
 * @title Notary
 * @author Kames Geraghty
 * @notice Notary is a minimal AccessControl layer for Citizen issuance.
 */
contract Notary is AccessControl {
  /// @notice CitizenAlpha instance
  address private _citizenAlpha;

  /// @notice Notary Role
  bytes32 private constant NOTARY = keccak256("NOTARY");

  /**
   * @notice Notary Constructor
   * @dev Set CitizenAlpha instance and set start Notaries.
   * @param _citizenAlpha_ CitizenAlpha instance
   * @param _notaries Array of Notaries
   */
  constructor(address _citizenAlpha_, address[] memory _notaries) {
    _citizenAlpha = _citizenAlpha_;
    _setupRole(NOTARY, address(this));
    for (uint256 i = 0; i < _notaries.length; i++) {
      _setupRole(DEFAULT_ADMIN_ROLE, _notaries[i]);
      _setupRole(NOTARY, _notaries[i]);
    }
    _setRoleAdmin(NOTARY, DEFAULT_ADMIN_ROLE);
  }

  /* ===================================================================================== */
  /* External Functions                                                                    */
  /* ===================================================================================== */

  function getCitizenAlpha() external view returns (address) {
    return _citizenAlpha;
  }

  /**
   * @notice Check Notary status
   * @param citizen address
   * @return status bool
   */
  function isNotary(address citizen) external view returns (bool status) {
    return hasRole(NOTARY, citizen);
  }

  /**
   * @notice Issue Citizenship
   * @param to address
   */
  function issue(address to) external {
    require(hasRole(NOTARY, _msgSender()), "Notary:unauthorized-access");
    _issue(to);
  }

  /**
   * @notice Batch issue Citizenships
   * @param to address
   */
  function issueBatch(address[] calldata to) external {
    require(hasRole(NOTARY, _msgSender()), "Notary:unauthorized-access");
    for (uint256 i = 0; i < to.length; i++) {
      _issue(to[i]);
    }
  }

  /**
   * @notice Revoke Citizenship
   * @param from address
   */
  function revoke(address from) external {
    require(hasRole(NOTARY, _msgSender()), "Notary:unauthorized-access");
    _revoke(from);
  }

  /**
   * @notice Batch Revoke Citizenships
   * @param from address
   */
  function revokeBatch(address[] calldata from) external {
    require(hasRole(NOTARY, _msgSender()), "Notary:unauthorized-access");
    for (uint256 i = 0; i < from.length; i++) {
      _revoke(from[i]);
    }
  }

  /* ===================================================================================== */
  /* Internal Functions                                                                    */
  /* ===================================================================================== */

  function _issue(address _to) internal {
    ICitizenAlpha(_citizenAlpha).issue(_to);
  }

  function _revoke(address _from) internal {
    ICitizenAlpha(_citizenAlpha).revoke(_from);
  }
}
