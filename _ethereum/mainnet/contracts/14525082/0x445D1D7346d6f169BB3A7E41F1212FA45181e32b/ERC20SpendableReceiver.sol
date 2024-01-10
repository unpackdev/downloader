// SPDX-License-Identifier: MIT
// Omnus Contracts (contracts/token/ERC20Spendable/SpendableERC20Receiver.sol)
// https://omnuslab.com/spendable

// ERC20SpendableReceiver (Lightweight library for allowing contract interaction on token transfer).

pragma solidity ^0.8.13;

/**
*
* @dev ERC20SpendableReceiver - library contract for an ERC20 extension to allow ERC20s to 
* operate as 'spendable' items, i.e. a token that can trigger an action on another contract
* at the same time as being transfered. Similar to ERC677 and the hooks in ERC777, but with more
* of an empasis on interoperability (returned values) than ERC677 and specifically scoped interaction
* rather than the general hooks of ERC777. 
*
* This library contract allows a smart contract to operate as a receiver of ERC20Spendable tokens.
*
*/

import "./Context.sol";
import "./Ownable.sol";   
import "./IERC20SpendableReceiver.sol"; 

/**
*
* @dev ERC20SpendableReceiver.
*
*/
abstract contract ERC20SpendableReceiver is Context, Ownable, IERC20SpendableReceiver {
  
  address public immutable ERC20Spendable; 

  event ERC20Received(address _caller, uint256 _tokenPaid, uint256[] _arguments);

  /** 
  *
  * @dev must be passed the token contract for the payable ERC20:
  *
  */ 
  constructor(address _ERC20Spendable) {
    ERC20Spendable = _ERC20Spendable;
  }

  /** 
  *
  * @dev Only allow authorised token:
  *
  */ 
  modifier onlyERC20Spendable(address _caller) {
    require (_caller == ERC20Spendable, "Call from unauthorised caller");
    _;
  }

  /** 
  *
  * @dev function to be called on receive. Must be overriden, including the addition of a fee check, if required:
  *
  */ 
  function receiveSpendableERC20(address _caller, uint256 _tokenPaid, uint256[] memory _arguments) external virtual onlyERC20Spendable(msg.sender) returns(bool, uint256[] memory) { 
    // Must be overriden 
  }

}
