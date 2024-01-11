// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";

/// @title $CYBER
/// @author @ryeshrimp

contract CYBER is ERC20, Ownable {

  /// @notice a mapping from an address to whether or not it can mint / burn
  mapping(address => bool) controllers;
  
  constructor() ERC20("CYBER", "CYBER") {
    controllers[msg.sender] = true;
  }

  /// @notice mints $CYBER to a recipient
  /// @param to the recipient of the $CYBER
  /// @param amount the amount of $CYBER to mint
  function mint(address to, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can mint");
    _mint(to, amount);
  }

  /// @notice burns $CYBER from a holder
  /// @param from the holder of the $CYBER
  /// @param amount the amount of $CYBER to burn
  function burn(address from, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can burn");
    _burn(from, amount);
  }

  /// @notice Adds an address from controller
  /// @dev This is used for contracts to burn/mint
  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  /// @notice Removes an address from controller
  /// @dev This is used for contracts to burn/mint
  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }
}