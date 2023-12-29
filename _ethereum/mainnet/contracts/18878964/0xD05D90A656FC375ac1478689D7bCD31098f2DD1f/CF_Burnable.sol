// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "./CF_Common.sol";
import "./CF_ERC20.sol";

abstract contract CF_Burnable is CF_Common, CF_ERC20 {
  /// @notice Total amount of tokens burned so far
  function totalBurned() external view returns (uint256) {
    return _totalBurned;
  }

  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }

  function burnFrom(address account, uint256 amount) external {
    _spendAllowance(account, msg.sender, amount);
    _burn(account, amount);
  }

  function _burn(address account, uint256 amount) internal virtual {
    require(_balance[account] >= amount, "Exceeds balance");

    unchecked {
      _balance[account] -= amount;
      _totalSupply -= amount;
      _totalBurned += amount;
    }

    emit Transfer(account, address(0xdEaD), amount);
  }
}
