// SPDX-License-Identifier: MIT
// Omnus Contracts (contracts/token/ERC20Spendable/ERC20Spendable.sol)
// https://omnuslab.com/spendable

// ERC20Spendable 

pragma solidity ^0.8.13;

/**
*
* @dev ERC20Spendable - library contract for an ERC20 extension to allow ERC20s to 
* operate as 'spendable' items, i.e. a token that can trigger an action on another contract
* at the same time as being transfered. Similar to ERC677 and the hooks in ERC777, but with more
* of an empasis on interoperability (returned values) than ERC677 and specifically scoped interaction
* rather than the general hooks of ERC777. 
*
*/

import "./Context.sol";  
import "./ERC20.sol";
import "./IERC20SpendableReceiver.sol";  

/**
*
* @dev ERC20Spendable is an extension of ERC20:
*
*/
abstract contract ERC20Spendable is Context, ERC20 {

  /**
  *
  * @dev New function, spendToken, that allows the transfer of the owners token to the receiver, a call on the receiver, and 
  * the return of information from the receiver back up the call stack:
  *
  */
  function spendToken(address receiver, uint256 _tokenPaid, uint256[] memory _arguments) external returns(uint256[] memory) {

    /**
    *
    * @dev Transfer tokens to the receiver contract IF this is a non-0 amount. Don't try and transfer 0, which leaves
    * open the possibility that the call is free. If not, the function call after will fail and revert.
    *
    */
    if (_tokenPaid != 0) transfer(receiver, _tokenPaid); 

    /**
    *
    * @dev Perform actions on the receiver and return arguments back up the callstack:
    *
    */
    (bool success, uint256[] memory returnValues) = IERC20SpendableReceiver(receiver).receiveSpendableERC20(msg.sender, _tokenPaid, _arguments);
    
    require(success, "Token Spend failed");
    
    return(returnValues);

  }

}