// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/*
 * @dev Provides information about the current execution context, specifically on if an account is an EOA on that chain.
 * Different chains have different account abstractions, so this contract helps to switch behaviour between chains.
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract EOAContext {
  function _isEOA(address account) internal view virtual returns (bool) {
      return account == tx.origin; // solhint-disable-line avoid-tx-origin
  }
}
