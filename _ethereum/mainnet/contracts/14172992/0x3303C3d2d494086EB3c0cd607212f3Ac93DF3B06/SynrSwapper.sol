// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./SyndicateERC20.sol";
import "./SyntheticSyndicateERC20.sol";
import "./AccessControl.sol";

// import "./console.sol";

/**
 * @title Syn Swapper
 *
 * @notice A contract to swap sSYNR for an indentical amount of SYNR
 *         The contract must have ssynr.ROLE_TOKEN_DESTROYER and
 *         synr.ROLE_TOKEN_CREATOR roles
 *
 * @author Francesco Sullo
 */
contract SynrSwapper is AccessControl {
  event SynSwapped(address swapper, uint256 amount);

  address public owner;
  SyndicateERC20 public synr;
  SyntheticSyndicateERC20 public ssynr;

  constructor(
    address _superAdmin,
    address _synr,
    address _ssynr
  ) AccessControl(_superAdmin) {
    synr = SyndicateERC20(_synr);
    ssynr = SyntheticSyndicateERC20(_ssynr);
  }

  /**
   * @notice Swaps an amount of sSYNR for an identical amount of SYNR
   *         Everyone can execute it, but it will have effect only if the recipient
   *         has the required roles.
   * @param amount     The amount of token to be swapped
   */
  function swap(uint256 amount) external {
    require(synr.isOperatorInRole(msg.sender, synr.ROLE_TREASURY()), "SYNR: not a treasury");
    ssynr.burn(msg.sender, amount);
    synr.mint(msg.sender, amount);
  }
}
