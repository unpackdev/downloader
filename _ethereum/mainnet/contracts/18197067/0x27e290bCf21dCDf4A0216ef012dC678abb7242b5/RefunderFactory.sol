// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";

import "./UpgradeableBeacon.sol";
import "./BeaconProxy.sol";

import "./AdminProxyManager.sol";
import "./IRefunderFactory.sol";
import "./IRefunder.sol";
import "./Refunder.sol";

contract RefunderFactory is
  Initializable,
  UUPSUpgradeable,
  OwnableUpgradeable,
  PausableUpgradeable,
  AdminProxyManager,
  IRefunderFactory
{
  address public override beacon;
  address[] public override allRefunds; // all refunds created

  function init(address _beacon) external proxied initializer {
    __UUPSUpgradeable_init();
    __Pausable_init();
    __Ownable_init();
    __AdminProxyManager_init(_msgSender());

    beacon = _beacon;
  }

  function _authorizeUpgrade(address newImplementation) internal virtual override proxied {}

  /**
   * @dev Get total number of refunds created
   */
  function allRefundsLength() public view virtual override returns (uint256) {
    return allRefunds.length;
  }

  /**
   * @dev Get owner
   */
  function owner() public view virtual override(IRefunderFactory, OwnableUpgradeable) returns (address) {
    return super.owner();
  }

  /**
   * @dev Initialize vesting token distribution
   * @param _stable Token project address
   * @param _projectOwner Project owner address
   * @param _payToProjectOwnerAt Payment start to project owner (epoch)
   */
  function createRefund(
    address _stable,
    address _projectOwner,
    uint256 _payToProjectOwnerAt
  ) public virtual override onlyOwner whenNotPaused returns (address refund) {
    bytes memory data = abi.encodeWithSelector(IRefunder.init.selector, _stable, _projectOwner, _payToProjectOwnerAt);

    refund = address(new BeaconProxy(beacon, data));

    allRefunds.push(refund);

    emit RefundCreated(refund, allRefunds.length - 1);
  }

  /**
   * @dev Pause factory activity
   */
  function togglePause() external virtual onlyOwner {
    if (paused()) {
      _unpause();
    } else {
      _pause();
    }
  }
}
