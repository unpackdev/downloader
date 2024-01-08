// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IGOLD.sol";

contract GOLD is IGOLD, ERC20, Ownable {

  // a mapping from an address to whether or not it can mint/burn
  mapping(address => bool) private controllers;

  /**
   * create the contract with a name and symbol
   */
  constructor() ERC20("GOLD", "GOLD") {}

  /**
   * mints $GOLD to a recipient
   * @param to the recipient of the $GOLD
   * @param amount the amount of $GOLD to mint
   */
  function mint(address to, uint256 amount) external override {
    require(controllers[_msgSender()], "GOLD: Only controllers can mint");

    _mint(to, amount);
  }

  /**
   * burns $GOLD from a holder
   * @param from the holder of the $GOLD
   * @param amount the amount of $GOLD to burn
   */
  function burn(address from, uint256 amount) external override {
    require(controllers[_msgSender()], "GOLD: Only controllers can burn");

    _burn(from, amount);
  }

  /**
   * enables an address to mint/burn
   * @param controller the address to enable
   */
  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  /**
   * disables an address from minting/burning
   * @param controller the address to disbale
   */
  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }

}
