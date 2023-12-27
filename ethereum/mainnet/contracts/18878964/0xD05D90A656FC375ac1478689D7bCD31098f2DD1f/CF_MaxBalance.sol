// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "./CF_Ownable.sol";
import "./CF_Common.sol";

abstract contract CF_MaxBalance is CF_Ownable, CF_Common {
  event SetMaxBalancePercent(uint24 percent);
  event RenouncedMaxBalance();

  /// @notice Permanently renounce and prevent the owner from being able to update the max. balance
  /// @dev Existing settings will continue to be effective
  function renounceMaxBalance() external onlyOwner {
    _renounced.MaxBalance = true;

    emit RenouncedMaxBalance();
  }

  /// @notice Percentage of the max. balance per wallet, depending on total supply
  function getMaxBalancePercent() external view returns (uint24) {
    return _maxBalancePercent;
  }

  /// @notice Set the max. percentage of a wallet balance, depending on total supply
  /// @param percent Desired percentage, multiplied by denominator
  function setMaxBalancePercent(uint24 percent) external onlyOwner {
    require(!_renounced.MaxBalance);

    unchecked {
      require(percent <= 100 * _denominator);
    }

    _setMaxBalancePercent(percent);

    emit SetMaxBalancePercent(percent);
  }

  function _setMaxBalancePercent(uint24 percent) internal {
    _maxBalancePercent = percent;
    _maxBalanceAmount = percent > 0 ? _percentage(_totalSupply, uint256(percent)) : 0;

    if (!_initialized) { emit SetMaxBalancePercent(percent); }
  }
}
