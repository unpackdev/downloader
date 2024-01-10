// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "./AccessControl.sol";
import "./EnumerableSet.sol";
import "./ITrancheToken.sol";
import "./IRegistry.sol";
import "./OndoLibrary.sol";
import "./IWETH.sol";

/**
 * @title Global values used by many contracts
 * @notice This is mostly used for access control
 */
contract Registry is IRegistry, AccessControl {
  using EnumerableSet for EnumerableSet.AddressSet;
  bool private _paused;
  mapping(bytes32 => bool) private featureFlags;

  uint256 public constant override denominator = 10000;

  IWETH public immutable override weth;

  address payable public fallbackRecipient;

  mapping(address => string) public strategistNames;

  modifier onlyRole(bytes32 _role) {
    require(hasRole(_role, msg.sender), "Unauthorized: Invalid role");
    _;
  }

  constructor(
    address _governance,
    address payable _fallbackRecipient,
    address _weth
  ) {
    require(
      _fallbackRecipient != address(0) && _fallbackRecipient != address(this),
      "Invalid address"
    );
    require(_governance != address(0), "Invalid governance address");
    require(_weth != address(0), "Invalid weth address");
    _setupRole(DEFAULT_ADMIN_ROLE, _governance);
    _setupRole(OLib.GOVERNANCE_ROLE, _governance);
    _setRoleAdmin(OLib.VAULT_ROLE, OLib.DEPLOYER_ROLE);
    _setRoleAdmin(OLib.ROLLOVER_ROLE, OLib.DEPLOYER_ROLE);
    _setRoleAdmin(OLib.STRATEGY_ROLE, OLib.DEPLOYER_ROLE);
    fallbackRecipient = _fallbackRecipient;
    weth = IWETH(_weth);
  }

  /**
   * @notice General ACL check
   * @param _role One of the predefined roles
   * @param _account Address to check
   * @return Access/Denied
   */
  function authorized(bytes32 _role, address _account)
    public
    view
    override
    returns (bool)
  {
    return hasRole(_role, _account);
  }

  /**
   * @notice Add a new official strategist
   * @dev grantRole protects this ACL
   * @param _strategist Address of new strategist
   * @param _name Display name for UI
   */
  function addStrategist(address _strategist, string calldata _name) external {
    grantRole(OLib.STRATEGIST_ROLE, _strategist);
    strategistNames[_strategist] = _name;
  }

  /**
   * Enables a feature flag.
   */
  function enableFeatureFlag(bytes32 _featureFlag)
    external
    override
    onlyRole(OLib.GOVERNANCE_ROLE)
  {
    featureFlags[_featureFlag] = true;
  }

  /**
   * Disables a feature flag.
   */
  function disableFeatureFlag(bytes32 _featureFlag)
    external
    override
    onlyRole(OLib.GOVERNANCE_ROLE)
  {
    featureFlags[_featureFlag] = false;
  }

  /**
   * Returns a feature flag value.
   */
  function getFeatureFlag(bytes32 _featureFlag)
    external
    view
    override
    returns (bool)
  {
    return featureFlags[_featureFlag];
  }

  /**
   * Removes a feature flag.
   */
  function deleteFeatureFlag(bytes32 _featureFlag)
    external
    override
    onlyRole(OLib.GOVERNANCE_ROLE)
  {
    delete featureFlags[_featureFlag];
  }

  /**
   * @dev Emitted when the pause is triggered by `account`.
   */
  event Paused(address account);

  /**
   * @dev Emitted when the pause is lifted by `account`.
   */
  event Unpaused(address account);

  /*
   * @notice Helper to expose a Pausable interface to tools
   */
  function paused() public view override returns (bool) {
    return _paused;
  }

  /**
   * @notice Turn on paused variable. Everything stops!
   */
  function pause() external override onlyRole(OLib.PANIC_ROLE) {
    _paused = true;
    emit Paused(msg.sender);
  }

  /**
   * @notice Turn off paused variable. Everything resumes.
   */
  function unpause() external override onlyRole(OLib.GUARDIAN_ROLE) {
    _paused = false;
    emit Unpaused(msg.sender);
  }

  /**
   * @notice Who will get any random eth from dead tranchetokens
   * @param _target Receipient of ETH
   */
  function setFallbackRecipient(address payable _target)
    external
    onlyRole(OLib.GOVERNANCE_ROLE)
  {
    fallbackRecipient = _target;
  }
}
