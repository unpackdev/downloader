// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./ERC20.sol";
import "./ERC20Capped.sol";
import "./draft-ERC20Permit.sol";

contract SinapsToken is
  ERC20,
  ERC20Permit,
  ERC20Capped
{

  /**
   * Constructor which defines the token ERC20 with a capped value
   * @param owner Address of the owner
   */
  constructor(
    address owner
    
  )
    ERC20("SinapsToken", "SNPS")
    ERC20Permit("SinapsToken")
    ERC20Capped(100_000_000 * 10**18)
  {
    _mint(owner, 100_000_000 * 10**18);

  }

  /**
   * Mint tokens
   * @param amount Amount of tokens to buy
   * @param account Account to buy tokens
   */
  function _mint(address account, uint256 amount)
    internal
    virtual
    override(ERC20, ERC20Capped)
  {
    ERC20._mint(account, amount);
  }

}