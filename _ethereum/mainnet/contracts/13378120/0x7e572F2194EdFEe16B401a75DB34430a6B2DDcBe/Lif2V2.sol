// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Lif2.sol";

/**
 * @dev Lif ERC20 token V2
 */
contract Lif2V2 is Lif2 {

  /**
   * @dev See {IERC20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - `recipient` cannot be the token contract itself
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    require(
      recipient != address(this),
      "ERC20: transfer to the contract"
    );
    _transfer(_msgSender(), recipient, amount);
    return true;
  }
}
