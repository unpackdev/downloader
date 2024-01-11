// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./Keep3rMeteredJob.sol";
import "./Keep3rBondedJob.sol";
import "./OnlyEOA.sol";

import "./IKeep3rStealthJob.sol";
import "./IStealthRelayer.sol";

abstract contract Keep3rMeteredStealthJob is IKeep3rStealthJob, Keep3rMeteredJob, Keep3rBondedJob, OnlyEOA {
  /// @inheritdoc IKeep3rStealthJob
  address public stealthRelayer;

  // methods

  /// @inheritdoc IKeep3rStealthJob
  function setStealthRelayer(address _stealthRelayer) public onlyGovernor {
    _setStealthRelayer(_stealthRelayer);
  }

  // modifiers

  modifier onlyStealthRelayer() {
    if (msg.sender != stealthRelayer) revert OnlyStealthRelayer();
    _;
  }

  modifier upkeepStealthy() {
    uint256 _initialGas = _getGasLeft();
    if (msg.sender != stealthRelayer) revert OnlyStealthRelayer();
    address _keeper = IStealthRelayer(stealthRelayer).caller();
    _isValidKeeper(_keeper);

    _;

    uint256 _gasAfterWork = _getGasLeft();
    uint256 _reward = (_calculateGas(_initialGas - _gasAfterWork + gasBonus) * gasMultiplier) / BASE;
    uint256 _payment = IKeep3rHelper(keep3rHelper).quote(_reward);
    IKeep3rV2(keep3r).bondedPayment(_keeper, _payment);
    emit GasMetered(_initialGas, _gasAfterWork, gasBonus);
  }

  // internals

  function _isValidKeeper(address _keeper) internal override(Keep3rBondedJob, Keep3rJob) {
    if (onlyEOA) _validateEOA(_keeper);
    super._isValidKeeper(_keeper);
  }

  function _setStealthRelayer(address _stealthRelayer) internal {
    stealthRelayer = _stealthRelayer;
    emit StealthRelayerSet(_stealthRelayer);
  }

  /// @notice Return the gas left and add 1/64 in order to match real gas left at first level of depth (EIP-150)
  function _getGasLeft() internal view returns (uint256 _gasLeft) {
    _gasLeft = (gasleft() * 64) / 63;
  }
}
