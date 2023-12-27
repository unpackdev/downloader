// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "./CF_Ownable.sol";
import "./CF_Common.sol";

abstract contract CF_Recoverable is CF_Ownable, CF_Common {
  /// @notice Recovers a misplaced amount of an ERC-20 token sitting in the contract balance
  /// @dev Beware of scam tokens!
  /// @dev Amounts allocated for tax distribution and liquidity cannot be recovered unless forced
  /// @param token Address of the ERC-20 token
  /// @param to Recipient
  /// @param amount Amount to be transferred
  /// @param force Retrieve amounts allocated for tax distribution and liquidity if needed
  function recoverERC20(address token, address to, uint256 amount, bool force) external onlyOwner {
    unchecked {
      uint256 balance = IERC20(token).balanceOf(address(this));
      uint256 allocated = token == address(this) ? _amountForTaxDistribution + _amountForLiquidity : (address(_reflectionToken) == token ? _reflectionTokensForTaxDistribution : 0);

      require((!force && balance - (allocated >= balance ? balance : allocated) >= amount) || (force && balance >= amount), "Exceeds balance");

      if (force && (token == address(this) || address(_reflectionToken) == token) && balance - (allocated >= balance ? balance : allocated) < amount) {
        require(!_distributing && !_swapping);

        if (token == address(this)) {
          uint256 pickFromAmountForTaxDistribution = amount >= _amountForTaxDistribution ? _amountForTaxDistribution : _amountForTaxDistribution - amount;

          _amountForTaxDistribution -= pickFromAmountForTaxDistribution;
          allocated -= pickFromAmountForTaxDistribution;

          if (balance - (allocated >= balance ? balance : allocated) < amount) { _amountForLiquidity -= amount >= _amountForLiquidity ? _amountForLiquidity : _amountForLiquidity - amount; }
        } else if (address(_reflectionToken) == token) {
          _reflectionTokensForTaxDistribution -= amount >= _reflectionTokensForTaxDistribution ? _reflectionTokensForTaxDistribution : _reflectionTokensForTaxDistribution - amount;
        }
      }
    }

    IERC20(token).transfer(to, amount);
  }

  /// @notice Recovers a misplaced amount of native ETH sitting in the contract balance
  /// @dev Amounts allocated for tax distribution and/or liquidity cannot be recovered unless forced
  /// @param to Recipient
  /// @param amount Amount of ETH to be transferred
  /// @param force Retrieve amounts allocated for tax distribution and liquidity if needed
  function recoverETH(address payable to, uint256 amount, bool force) external onlyOwner {
    unchecked {
      uint256 balance = address(this).balance;
      uint256 allocated = address(_reflectionToken) == _dex.WETH ? _ethForTaxDistribution : 0;

      require((!force && balance - (allocated >= balance ? balance : allocated) >= amount) || (force && balance >= amount), "Exceeds balance");

      if (force && address(_reflectionToken) == _dex.WETH && balance - (allocated >= balance ? balance : allocated) < amount) {
        require(!_distributing && !_swapping);

        _ethForTaxDistribution -= amount >= _ethForTaxDistribution ? _ethForTaxDistribution : _ethForTaxDistribution - amount;
      }
    }

    (bool success, ) = to.call{ value: amount }("");

    require(success);
  }
}
