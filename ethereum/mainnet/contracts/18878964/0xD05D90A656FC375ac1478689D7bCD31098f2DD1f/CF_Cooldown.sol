// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "./CF_Ownable.sol";
import "./CF_Common.sol";

abstract contract CF_Cooldown is CF_Ownable, CF_Common {
  event SetCooldown(uint8 count, uint32 time, uint32 period);
  event RenouncedCooldown();

  /// @notice Permanently renounce and prevent the owner from being able to update cooldown features
  /// @dev Existing settings will continue to be effective
  function renounceCooldown() external onlyOwner {
    _renounced.Cooldown = true;

    emit RenouncedCooldown();
  }

  /// @notice Set cooldown settings
  /// @param count Number of transfers
  /// @param time Seconds during which the number of transfers will be taken into account
  /// @param period Seconds during which the wallet will be in cooldown
  function setCooldown(uint8 count, uint32 time, uint32 period) external onlyOwner {
    require(!_renounced.Cooldown);

    _setCooldown(count, time, period);
  }

  function _setCooldown(uint8 count, uint32 time, uint32 period) internal {
    require(count > 1 && time > 5);

    _cooldownTriggerCount = count;
    _cooldownTriggerTime = time;
    _cooldownPeriod = period;

    emit SetCooldown(count, time, period);
  }

  function _cooldown(address account) internal {
    unchecked {
      _holder[account].cooldown = _timestamp() + _cooldownPeriod;
    }
  }

  /// @notice Removes the cooldown status of a wallet
  /// @param account Address to unfreeze
  function removeCooldown(address account) external onlyOwner {
    require(!_renounced.Cooldown);

    _holder[account].count = 0;
    _holder[account].start = 0;
    _holder[account].cooldown = 0;
  }

  /// @notice Check if a wallet is currently in cooldown
  /// @param account Address to check
  /// @return Remaining seconds in cooldown
  function remainingCooldownTime(address account) public view returns (uint32) {
    if (_cooldownPeriod == 0 || !_holder[account].exists || _holder[account].cooldown < _timestamp()) { return 0; }

    unchecked {
      return _holder[account].cooldown - _timestamp();
    }
  }
}
