// SPDX-License-Identifier: MIT
// Omnus Contracts (contracts/token/ERC20Spendable/ISpendableERC20.sol)
// https://omnuslab.com/spendable

// IERC20Spendable - Interface definition for contracts to implement spendable ERC20 functionality

pragma solidity ^0.8.13;

/**
*
* @dev ERC20Spendable - library contract for an ERC20 extension to allow ERC20s to 
* operate as 'spendable' items, i.e. a token that can trigger an action on another contract
* at the same time as being transfered. Similar to ERC677 and the hooks in ERC777, but with more
* of an empasis on interoperability (returned values) than ERC677 and specifically scoped interaction
* rather than the general hooks of ERC777. 
*
* Interface Definition IERC20Spendable
*
*/

interface IERC20Spendable{

  /**
  *
  * @dev New function, spendToken, that allows the transfer of the owners token to the receiver, a call on the receiver, and 
  * the return of information from the receiver back up the call stack:
  *
  */
  function spendToken(address receiver, uint256 _tokenPaid, uint256[] memory _arguments) external returns(uint256[] memory);

}