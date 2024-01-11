// SPDX-License-Identifier: MIT
// Omnus Contracts (contracts/token/ERC20Spendable/ISpendableERC20.sol)
// https://omnuslab.com/spendable

// IERC20SpendableReceiver - Interface definition for contracts to implement spendable ERC20 functionality

pragma solidity ^0.8.13;

/**
*
* @dev IERC20SpendableReceiver - library contract for an ERC20 extension to allow ERC20s to 
* operate as 'spendable' items, i.e. a token that can trigger an action on another contract
* at the same time as being transfered. Similar to ERC677 and the hooks in ERC777, but with more
* of an empasis on interoperability (returned values) than ERC677 and specifically scoped interaction
* rather than the general hooks of ERC777. 
*
* This library contract allows a smart contract to operate as a receiver of ERC20Spendable tokens.
*
* Interface Definition IERC20SpendableReceiver
*
*/

interface IERC20SpendableReceiver{

  /** 
  *
  * @dev function to be called on receive. 
  *
  */ 
  function receiveSpendableERC20(address _caller, uint256 _tokenPaid, uint256[] memory arguments) external returns(bool, uint256[] memory);

}