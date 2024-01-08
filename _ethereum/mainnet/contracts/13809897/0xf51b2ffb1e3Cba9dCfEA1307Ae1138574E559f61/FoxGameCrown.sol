/*
███████╗ ██████╗ ██╗  ██╗     ██████╗  █████╗ ███╗   ███╗███████╗
██╔════╝██╔═══██╗╚██╗██╔╝    ██╔════╝ ██╔══██╗████╗ ████║██╔════╝
█████╗  ██║   ██║ ╚███╔╝     ██║  ███╗███████║██╔████╔██║█████╗  
██╔══╝  ██║   ██║ ██╔██╗     ██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  
██║     ╚██████╔╝██╔╝ ██╗    ╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗
╚═╝      ╚═════╝ ╚═╝  ╚═╝     ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC20PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";

import "./IFoxGameCrown.sol";

contract FoxGameCrown is IFoxGameCrown, ERC20PausableUpgradeable, OwnableUpgradeable {

  // Allowlist of addresses to mint or burn
  mapping(address => bool) public controllers;
  
  function initialize() public initializer {
    __ERC20_init("FoxGame", "CROWN");
    __ERC20Pausable_init();
    __Ownable_init();
  }

  /**
   * Mint $CARROT to a recipient.
   * @param to the recipient of the $CARROT
   * @param amount the amount of $CARROT to mint
   */
  function mint(address to, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can mint");
    _mint(to, amount);
  }

  /**
   * Burn $CARROT from a holder.
   * @param from the holder of the $CARROT
   * @param amount the amount of $CARROT to burn
   */
  function burn(address from, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can burn");
    _burn(from, amount);
  }

  /**
   * Enables an address to mint / burn.
   * @param controller the address to enable
   */
  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  /**
   * Disables an address from minting / burning.
   * @param controller the address to disbale
   */
  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }

  /**
   * Toggle pausing token transfers.
   */
  function togglePause() external onlyOwner {
    if (paused()) {
      _unpause();
    } else {
      _pause();
    }
  }

  /**
   * Required override to support upgradable logic.
   */
  function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal
    override(ERC20PausableUpgradeable)
  {
    super._beforeTokenTransfer(from, to, amount);
  }
}
