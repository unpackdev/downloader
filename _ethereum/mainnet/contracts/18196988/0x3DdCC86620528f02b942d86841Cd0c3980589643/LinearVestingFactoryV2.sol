// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";

import "./UpgradeableBeacon.sol";
import "./BeaconProxy.sol";

import "./AdminProxyManager.sol";
import "./ILinearVestingFactoryV2.sol";
import "./ILinearVestingV2.sol";
import "./LinearVestingV2.sol";

contract LinearVestingFactoryV2 is
  Initializable,
  UUPSUpgradeable,
  OwnableUpgradeable,
  PausableUpgradeable,
  AdminProxyManager,
  ILinearVestingFactoryV2
{
  address public override beacon;
  address[] public override allVestings; // all vestings created

  function init(address _beacon) external proxied initializer {
    __UUPSUpgradeable_init();
    __Pausable_init();
    __Ownable_init();
    __AdminProxyManager_init(_msgSender());

    beacon = _beacon;
  }

  function _authorizeUpgrade(address newImplementation) internal virtual override proxied {}

  /**
   * @dev Get total number of vestings created
   */
  function allVestingsLength() public view virtual override returns (uint256) {
    return allVestings.length;
  }

  /**
   * @dev Get owner
   */
  function owner() public view virtual override(ILinearVestingFactoryV2, OwnableUpgradeable) returns (address) {
    return super.owner();
  }

  /**
   * @dev Initialize vesting token distribution
   * @param _token Token project address
   * @param _stable Stable token address
   * @param _tokenPrice Token price (in stable decimal)
   * @param _lastRefundAt Last datetime to refund (epoch)
   * @param _projectOwner Project owner address
   * @param _tgeAt TGE datetime in epoch
   * @param _tgeRatio_d2 TGE ratio in percent (2 decimal)
   * @param _startEndLinearDatetime Start & end Linear datetime in epoch
   */
  function createVesting(
    address _token,
    address _stable,
    address _projectOwner,
    uint256 _tokenPrice,
    uint256 _lastRefundAt,
    uint128 _tgeAt,
    uint128 _tgeRatio_d2,
    uint128[2] calldata _startEndLinearDatetime
  ) public virtual override onlyOwner whenNotPaused returns (address vesting) {
    require(_tokenPrice > 0, 'bad');

    bytes memory data = abi.encodeWithSelector(
      ILinearVestingV2.init.selector,
      _token,
      _stable,
      _projectOwner,
      _tokenPrice,
      _lastRefundAt,
      _tgeAt,
      _tgeRatio_d2,
      _startEndLinearDatetime
    );

    vesting = address(new BeaconProxy(beacon, data));

    allVestings.push(vesting);

    emit VestingCreated(vesting, allVestings.length - 1);
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
