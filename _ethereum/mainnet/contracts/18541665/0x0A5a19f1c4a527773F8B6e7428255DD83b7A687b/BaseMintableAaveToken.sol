// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseAaveToken.sol";

/**
 * @title BaseMintableAaveToken
 * @author BGD labs
 * @notice extension for BaseAaveToken adding mint/burn and transfer hooks
 */
contract BaseMintableAaveToken is BaseAaveToken {
  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   */
  function _mint(address account, uint104 amount) internal virtual {
    require(account != address(0), 'ERC20: mint to the zero address');

    uint104 balanceBefore = _balances[account].balance;
    _totalSupply += amount;
    _balances[account].balance += amount;
    emit Transfer(address(0), account, amount);

    _afterTokenTransfer(address(0), account, 0, balanceBefore, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint104 amount) internal virtual {
    require(account != address(0), 'ERC20: burn from the zero address');

    uint104 accountBalance = _balances[account].balance;
    require(accountBalance >= amount, 'ERC20: burn amount exceeds balance');
    unchecked {
      _balances[account].balance = accountBalance - amount;
      // Overflow not possible: amount <= accountBalance <= totalSupply.
      _totalSupply -= amount;
    }

    emit Transfer(account, address(0), amount);

    _afterTokenTransfer(account, address(0), accountBalance, 0, amount);
  }
}
