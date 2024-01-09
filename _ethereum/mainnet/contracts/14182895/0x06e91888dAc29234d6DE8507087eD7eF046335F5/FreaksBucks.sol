// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Ownable.sol";
import "./Pausable.sol";
import "./Controllable.sol";
import "./draft-ERC20Permit.sol";

/// @title Freaks Bucks
contract FreaksBucks is Ownable, Pausable, Controllable, ERC20, ERC20Permit {
  constructor() ERC20("Freaks Bucks", "FBX") ERC20Permit("Freaks Bucks") {}

  /* -------------------------------------------------------------------------- */
  /*                                ERC-20 Logic                                */
  /* -------------------------------------------------------------------------- */

  /// @notice Mint new tokens to `to` with amount of `value`.
  function mint(address to, uint256 value) external onlyController {
    super._mint(to, value);
  }

  /// @notice Burn tokens from `from` with amount of `value`.
  function burn(address from, uint256 value) external onlyController {
    super._burn(from, value);
  }

  /* -------------------------------------------------------------------------- */
  /*                                 Owner Logic                                */
  /* -------------------------------------------------------------------------- */

  /// @notice Add or edit contract controllers.
  /// @param addrs Array of addresses to be added/edited.
  /// @param state New controller state of addresses.
  function setControllers(address[] calldata addrs, bool state) external onlyOwner {
    for (uint256 i = 0; i < addrs.length; i++) super._setController(addrs[i], state);
  }

  /// @notice Pause the contract.
  function pause() external onlyOwner {
    super._pause();
  }

  /// @notice Unpause the contract.
  function unpause() external onlyOwner {
    super._unpause();
  }

  /* -------------------------------------------------------------------------- */
  /*                                    Super                                   */
  /* -------------------------------------------------------------------------- */

  /// @notice See {ERC20-_beforeTokenTransfer}.
  /// @dev Overriden to block transactions while the contract is paused (avoiding bugs).
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    require(isController(msg.sender) || !paused(), "Pausable: paused");
    super._beforeTokenTransfer(from, to, amount);
  }
}
