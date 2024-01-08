// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC20Capped.sol";
import "./Ownable.sol";

contract Aureus is ERC20Capped, Ownable {
  /** @dev - The constructor creates the ERC20 token and mints the cap amount
   * @param _name - The name of the ERC20 token that is deployed
   * @param _symbol - The symbol which will be used to distinguish the ERC20 token
   * @param _cap - The cap amount which can be minted of the ERC20 token
   */
  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _cap
  ) ERC20(_name, _symbol) ERC20Capped(_cap) {
    ERC20._mint(msg.sender, _cap);
  }

  /** @dev - A burn function to be called for the ERC20 token from another contract/user
   * @param _amount - The amount of ERC20 tokens to be burned
   */
  function burn(uint256 _amount) external {
    _burn(msg.sender, _amount);
  }
}
