// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./Keep3rJob.sol";
import "./IKeep3rHelper.sol";
import "./IKeep3rMeteredJob.sol";

abstract contract Keep3rMeteredJob is Keep3rJob, IKeep3rMeteredJob {
  address public override keep3rHelper = 0x12038d459166Ab8E68768bb35EC0AF765A36038D;
  /// @dev Fixed bonus to pay for unaccounted gas in small transactions
  uint256 public override gasBonus = 86_000;
  uint256 public override gasMaximum = 1_000_000;
  uint256 public override gasMultiplier = 12_000;
  uint32 public constant override BASE = 10_000;

  function setKeep3rHelper(address _keep3rHelper) public override onlyGovernor {
    keep3rHelper = _keep3rHelper;
    emit Keep3rHelperSet(_keep3rHelper);
  }

  function setGasBonus(uint256 _gasBonus) external override onlyGovernor {
    gasBonus = _gasBonus;
    emit GasBonusSet(gasBonus);
  }

  function setGasMaximum(uint256 _gasMaximum) external override onlyGovernor {
    gasMaximum = _gasMaximum;
    emit GasMaximumSet(gasMaximum);
  }

  function setGasMultiplier(uint256 _gasMultiplier) external override onlyGovernor {
    gasMultiplier = _gasMultiplier;
    emit GasMultiplierSet(gasMultiplier);
  }

  modifier upkeepMetered() {
    uint256 _initialGas = gasleft();
    _isValidKeeper(msg.sender);
    _;
    uint256 _gasAfterWork = gasleft();
    /// @dev Using revert strings to interact with CLI simulation
    require(_initialGas - _gasAfterWork <= gasMaximum, 'GasMeteredMaximum');
    uint256 _reward = (_calculateGas(_initialGas - _gasAfterWork + gasBonus) * gasMultiplier) / BASE;
    uint256 _payment = IKeep3rHelper(keep3rHelper).quote(_reward);
    IKeep3rV2(keep3r).bondedPayment(msg.sender, _payment);
    emit GasMetered(_initialGas, _gasAfterWork, gasBonus);
  }

  function _calculateGas(uint256 _gasUsed) internal view returns (uint256 _resultingGas) {
    _resultingGas = block.basefee * _gasUsed;
  }
}
