// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Admin.sol";

/** 
* @author Formation.Fi.
* @notice Implementation of the contract AdminBeta.
*/

contract AdminBeta is Admin {
    constructor(address _manager, address _treasury, address _stableToken,
     address _token) Admin(  _manager,  _treasury,  _stableToken,
     _token){
   }
}