// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./AccessControl.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";

abstract contract Slashable is AccessControl, IERC20 {
  using SafeERC20 for IERC20;

  /// @dev Precomputed hash for "SLASHER" role ID
  bytes32 public immutable SLASHER = keccak256("SLASHER");

  /// @dev Slash event
  event Slash(address indexed slasher, IERC20 token, uint256 amount);

  /// @dev The slashable asset
  function underlying() public view virtual returns (IERC20);

  /**
   * @dev Slash the pool by a given amount. Callable by the owner.
   * @param amount The amount of tokens to slash
   * @param receiver The recipient of the slashed assets
   */
  function slash(uint256 amount, address receiver) external onlyRole(SLASHER) {
    IERC20 token = underlying();
    require(
      token.balanceOf(address(this)) >= amount,
      "slash: insufficient balance"
    );

    token.safeTransfer(receiver, amount);
    emit Slash(msg.sender, token, amount);
  }
}
