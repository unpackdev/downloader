// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./console.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
interface IERC20Burnable {

  function burn(uint256 amount) external;

  function burnFrom( address account_, uint256 ammount_ ) external;
}