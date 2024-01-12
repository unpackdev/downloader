// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "./AccessControlEnumerable.sol";
import "./Ownable.sol";
import "./CitizenAlpha.sol";
import "./Notary.sol";

/**
 * @title Nation
 * @author Kames Geraghty
 * @notice Nation is an AccessControl layer for CitizenAlpha.
 * @dev Extends Citizen on-chain permissions using updatables nested Roles.
           
 */
contract Nation is AccessControlEnumerable {
  /// @notice CitizenAlpha instance
  address private _citizenAlpha;

  /// @notice Founder Role
  bytes32 private constant FOUNDER = keccak256("FOUNDER");

  /// @notice Governance Role
  bytes32 private constant GOVERNANCE = keccak256("GOVERNANCE");

  /// @notice Global Role AccessControl
  mapping(bytes32 => bool) private _roleActive;

  /**
   * @notice Nation Constructor
   * @param _founders addresses array of FOUNDERS
   */
  constructor(address _citizenAlpha_, address[] memory _founders) {
    _citizenAlpha = _citizenAlpha_;
    _roleActive[FOUNDER] = true;
    _roleActive[GOVERNANCE] = true;
    _roleActive[DEFAULT_ADMIN_ROLE] = true;
    for (uint256 i = 0; i < _founders.length; i++) {
      _setupRole(FOUNDER, _founders[i]);
      _setupRole(DEFAULT_ADMIN_ROLE, _founders[i]);
    }
    _setRoleAdmin(FOUNDER, DEFAULT_ADMIN_ROLE);
  }

  /**
   * @notice Admin modifier
   * @param role bytes32
   */
  modifier _onlyAdmin(bytes32 role) {
    address sender_ = _msgSender();
    require(
      hasRole(getRoleAdmin(role), sender_) ||
        hasRole(GOVERNANCE, sender_) ||
        hasRole(DEFAULT_ADMIN_ROLE, sender_),
      "Nation:unauthorized"
    );
    _;
  }

  /**
   * @notice Governance modifier
   */
  modifier _onlyGovernance() {
    address sender_ = _msgSender();
    require(
      (hasRole(GOVERNANCE, sender_) || hasRole(DEFAULT_ADMIN_ROLE, sender_)),
      "Nation:unauthorized"
    );
    _;
  }

  /* ===================================================================================== */
  /* External Functions                                                                    */
  /* ===================================================================================== */

  /**
   * @notice Get CitizenAlpha instance
   * @return citizenAlpha address of CitizenAlpha instance
   */
  function getCitizenAlpha() external view returns (address) {
    return _citizenAlpha;
  }

  /**
   * @notice Check if Account has Role
   * @dev Include check for Role activication is Citizenship
   * @return active bool
   */
  function hasRole(bytes32 role, address account)
    public
    view
    virtual
    override(AccessControl, IAccessControl)
    returns (bool)
  {
    if (!_roleActive[role] || !CitizenAlpha(_citizenAlpha).isCitizen(account)) {
      return false;
    }
    return super.hasRole(role, account);
  }

  /**
   * @notice Check Founder status
   * @param citizen address
   * @return status bool
   */
  function isFounder(address citizen) external view returns (bool status) {
    return hasRole(FOUNDER, citizen);
  }

  /**
   * @notice Check Governance status
   * @param module address
   * @return status bool
   */
  function isGovernance(address module) external view returns (bool status) {
    return hasRole(GOVERNANCE, module);
  }

  /**
   * @notice Get status of Role global settings
   * @return status bool
   */
  function roleStatus(bytes32 role) external view returns (bool status) {
    return _roleActive[role];
  }

  /**
   * @notice Grant Role to Citizen
   * @param role bytes32
   * @param citizen address
   */
  function grantRole(bytes32 role, address citizen)
    public
    virtual
    override(AccessControl, IAccessControl)
    _onlyAdmin(role)
  {
    require(_roleActive[role], "Nation:inactive-role");
    _grantRole(role, citizen);
  }

  /**
   * @notice Revoke Role from Citizen
   * @param role bytes32
   * @param citizen address
   */
  function revokeRole(bytes32 role, address citizen)
    public
    virtual
    override(AccessControl, IAccessControl)
    _onlyAdmin(role)
  {
    require(role != DEFAULT_ADMIN_ROLE, "Nation:invalid-request");
    require(_roleActive[role], "Nation:inactive-role");
    _revokeRole(role, citizen);
  }

  /**
   * @notice Enable Role status
   * @param role bytes32
   */
  function enableRole(bytes32 role) external onlyRole(FOUNDER) {
    require(_roleActive[role] == false, "Nation:role-enabled");
    _setRoleAdmin(role, FOUNDER);
    _roleActive[role] = true;
  }

  /**
   * @notice Enable Role status
   * @param role bytes32
   * @param adminRole bytes32
   */
  function enableRoleWithAdmin(bytes32 role, bytes32 adminRole) external _onlyGovernance {
    require(_roleActive[role] == false, "Nation:role-enabled");
    _setRoleAdmin(role, adminRole);
    _roleActive[role] = true;
  }

  /**
   * @notice Disable Role status
   * @param role bytes32
   */
  function disableRole(bytes32 role) external _onlyGovernance {
    require(_roleActive[role] == true, "Nation:role-disabled");
    _setRoleAdmin(role, DEFAULT_ADMIN_ROLE);
    _roleActive[role] = false;
  }

  /**
   * @notice Set Role admin
   * @param role bytes32
   * @param adminRole bytes32
   */
  function setRoleAdmin(bytes32 role, bytes32 adminRole) external _onlyGovernance {
    _setRoleAdmin(role, adminRole);
  }
}
