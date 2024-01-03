// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./UUPSUpgradeable.sol";
import {AccessControlDefaultAdminRulesUpgradeable} from
  "upgradeable/access/AccessControlDefaultAdminRulesUpgradeable.sol";
import {PausableUpgradeable} from
  "upgradeable/security/PausableUpgradeable.sol";

import "./IPolygonZkEVMBridge.sol";
import {PolygonERC20BridgeLibUpgradeable} from
  "./base/PolygonERC20BridgeLibUpgradeable.sol";

/**
 * @title WstETHBridgeL1
 * @author sepyke.eth
 * @notice Main smart contract to bridge wstETH from Ethereum to Polygon zkEVM
 */
contract WstETHBridgeL1 is
  UUPSUpgradeable,
  AccessControlDefaultAdminRulesUpgradeable,
  PausableUpgradeable,
  PolygonERC20BridgeLibUpgradeable
{
  using SafeERC20 for IERC20;

  /// @notice Role identifiers
  bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");

  /// @notice wstETH contract on Polygon zkEVM
  IERC20 public wrappedTokenAddress;

  /// @notice wstETH contract on Ethereum mainnet
  IERC20 public originTokenAddress;

  /// @notice wstETH origin from mainnet = 0; if from zkEVM then 1
  uint32 public originTokenNetwork = 0;

  /// @notice Disable initializer on deploy
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice WstETHBridgeL1 initializer
   * @param _adminAddress The admin address
   * @param _emergencyRoleAddress The emergency role address
   * @param _originTokenAddress The wstETH address on Ethereum mainnet
   * @param _wrappedTokenAddress The wstETHWrapped address on Polygon zkEVM
   * @param _polygonZkEVMBridge The Polygon zkEVM bridge address
   * @param _counterpartContract The token address on the Polygon zkEVM network
   * @param _counterpartNetwork The Polygon zkEVM ID on the bridge
   */
  function initialize(
    address _adminAddress,
    address _emergencyRoleAddress,
    IERC20 _wrappedTokenAddress,
    IERC20 _originTokenAddress,
    IPolygonZkEVMBridge _polygonZkEVMBridge,
    address _counterpartContract,
    uint32 _counterpartNetwork
  ) public initializer {
    __AccessControlDefaultAdminRules_init(3 days, _adminAddress);
    __UUPSUpgradeable_init();
    __Pausable_init();
    __PolygonERC20BridgeLib_init(
      _polygonZkEVMBridge, _counterpartContract, _counterpartNetwork
    );

    _grantRole(EMERGENCY_ROLE, _emergencyRoleAddress);

    wrappedTokenAddress = _wrappedTokenAddress;
    originTokenAddress = _originTokenAddress;
  }

  /**
   * @dev The WstETHBridgeL1 can only be upgraded by the owner
   * @param v new WstETHBridgeL1 implementation
   */
  function _authorizeUpgrade(address v)
    internal
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {}

  /**
   * @notice Pause the bridge
   * @dev Only EMERGENCY_ROLE can pause the bridge
   */
  function pause() external virtual onlyRole(EMERGENCY_ROLE) {
    _pause();
  }

  /**
   * @notice Resume the bridge
   * @dev Only EMERGENCY_ROLE can resume the bridge
   */
  function unpause() external virtual onlyRole(EMERGENCY_ROLE) {
    _unpause();
  }

  /**
   * @dev Handle the reception of the tokens
   * @param amount Token amount
   */
  function _receiveTokens(uint256 amount)
    internal
    virtual
    override
    whenNotPaused
  {
    originTokenAddress.safeTransferFrom(msg.sender, address(this), amount);
  }

  /**
   * @dev Handle the transfer of the tokens
   * @param destinationAddress Address destination that will receive the tokens
   * on the other network
   * @param amount Token amount
   */
  function _transferTokens(address destinationAddress, uint256 amount)
    internal
    virtual
    override
    whenNotPaused
  {
    originTokenAddress.safeTransfer(destinationAddress, amount);
  }
}
