// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./Keep3rJob.sol";
import "./IKeep3rHelper.sol";
import "./IKeep3rMeteredJob.sol";

abstract contract Keep3rMeteredJob is IKeep3rMeteredJob, Keep3rJob {
  /// @inheritdoc IKeep3rMeteredJob
  address public keep3rHelper = 0xD36Ac9Ff5562abb541F51345f340FB650547a661;
  /// @inheritdoc IKeep3rMeteredJob
  uint256 public gasBonus = 86_000;
  /// @inheritdoc IKeep3rMeteredJob
  uint256 public gasMultiplier = 12_000;
  /// @inheritdoc IKeep3rMeteredJob
  uint32 public constant BASE = 10_000;
  /// @inheritdoc IKeep3rMeteredJob
  uint256 public maxMultiplier = 15_000;

  // setters

  /// @inheritdoc IKeep3rMeteredJob
  function setKeep3rHelper(address _keep3rHelper) public onlyGovernor {
    _setKeep3rHelper(_keep3rHelper);
  }

  /// @inheritdoc IKeep3rMeteredJob
  function setGasBonus(uint256 _gasBonus) external onlyGovernor {
    _setGasBonus(_gasBonus);
  }

  /// @inheritdoc IKeep3rMeteredJob
  function setMaxMultiplier(uint256 _maxMultiplier) external onlyGovernor {
    _setMaxMultiplier(_maxMultiplier);
  }

  /// @inheritdoc IKeep3rMeteredJob
  function setGasMultiplier(uint256 _gasMultiplier) external onlyGovernor {
    _setGasMultiplier(_gasMultiplier);
  }

  // modifiers

  modifier upkeepMetered() {
    uint256 _initialGas = gasleft();
    _isValidKeeper(msg.sender);
    _;
    uint256 _gasAfterWork = gasleft();
    uint256 _reward = (_calculateGas(_initialGas - _gasAfterWork + gasBonus) * gasMultiplier) / BASE;
    uint256 _payment = IKeep3rHelper(keep3rHelper).quote(_reward);
    IKeep3rV2(keep3r).bondedPayment(msg.sender, _payment);
    emit GasMetered(_initialGas, _gasAfterWork, gasBonus);
  }

  // internals

  function _setKeep3rHelper(address _keep3rHelper) internal {
    keep3rHelper = _keep3rHelper;
    emit Keep3rHelperSet(_keep3rHelper);
  }

  function _setGasBonus(uint256 _gasBonus) internal {
    gasBonus = _gasBonus;
    emit GasBonusSet(gasBonus);
  }

  function _setMaxMultiplier(uint256 _maxMultiplier) internal {
    maxMultiplier = _maxMultiplier;
    emit MaxMultiplierSet(maxMultiplier);
  }

  function _setGasMultiplier(uint256 _gasMultiplier) internal {
    if (_gasMultiplier > maxMultiplier) revert MaxMultiplier();
    gasMultiplier = _gasMultiplier;
    emit GasMultiplierSet(gasMultiplier);
  }

  function _calculateGas(uint256 _gasUsed) internal view returns (uint256 _resultingGas) {
    _resultingGas = block.basefee * _gasUsed;
  }

  function _calculateCredits(uint256 _gasUsed) internal view returns (uint256 _credits) {
    return IKeep3rHelper(keep3rHelper).getRewardAmount(_calculateGas(_gasUsed));
  }
}
