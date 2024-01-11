//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
 * HOPS: the utility and governance token of the Cyber Roo universe.
 * The Cyber Roo developers do not provide a secondary marketplace for HOPS.
 */

import "./ERC20.sol";
import "./Ownable.sol";

contract HOPS is ERC20, Ownable {

  // a mapping from an address to whether or not it can mint / burn. Cyber Roos official contracts only
  mapping(address => bool) public controllers;
  
  constructor() ERC20("HOPS: Cyber Roos", "HOPS") { } 

  /**
   * mints $HOPS to a recipient
   * @param to - the recipient of the $HOPS
   * @param amount - the amount of $HOPS to mint
   */
  function mint(address to, uint256 amount) external {
    require(controllers[_msgSender()], "Only controllers can mint");
    _mint(to, amount);
  }

  /**
   * burns $HOPS from a holder
   * @param from the holder of the $HOPS
   * @param amount the amount of $HOPS to burn
   */
  function burn(address from, uint256 amount) external {
    require(controllers[_msgSender()], "Only controllers can burn");
    _burn(from, amount);
  }

  /**
   * enables an address to mint / burn (Cyber Roos official contracts only)
   * @param controller the address to enable
   */
  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  /**
   * disables an address from minting / burning
   * @param controller the address to disable
   */
  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }
}