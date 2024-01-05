// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./Ownable.sol";

import "./PausableFeature.sol";
import "./FreezableFeature.sol";

/**
 * @dev Support for "SRC20 feature" modifier.
 */
contract Features is PausableFeature, FreezableFeature, Ownable {
  uint8 public features;
  uint8 public constant ForceTransfer = 0x01;
  uint8 public constant Pausable = 0x02;
  uint8 public constant AccountBurning = 0x04;
  uint8 public constant AccountFreezing = 0x08;
  uint8 public constant TransferRules = 0x10;

  modifier enabled(uint8 feature) {
    require(isEnabled(feature), 'Features: Token feature is not enabled');
    _;
  }

  event FeaturesUpdated(
    bool forceTransfer,
    bool tokenFreeze,
    bool accountFreeze,
    bool accountBurn,
    bool transferRules
  );

  constructor(address _owner, uint8 _features) {
    _enable(_features);
    transferOwnership(_owner);
  }

  function _enable(uint8 _features) internal {
    features = _features;
    emit FeaturesUpdated(
      _features & ForceTransfer != 0,
      _features & Pausable != 0,
      _features & AccountBurning != 0,
      _features & AccountFreezing != 0,
      _features & TransferRules != 0
    );
  }

  function isEnabled(uint8 _feature) public view returns (bool) {
    return features & _feature != 0;
  }

  function checkTransfer(address _from, address _to) external view returns (bool) {
    return !_isAccountFrozen(_from) && !_isAccountFrozen(_to) && !paused;
  }

  function isAccountFrozen(address _account) external view returns (bool) {
    return _isAccountFrozen(_account);
  }

  function freezeAccount(address _account) external enabled(AccountFreezing) onlyOwner {
    _freezeAccount(_account);
  }

  function unfreezeAccount(address _account) external enabled(AccountFreezing) onlyOwner {
    _unfreezeAccount(_account);
  }

  function pause() external enabled(Pausable) onlyOwner {
    _pause();
  }

  function unpause() external enabled(Pausable) onlyOwner {
    _unpause();
  }
}
