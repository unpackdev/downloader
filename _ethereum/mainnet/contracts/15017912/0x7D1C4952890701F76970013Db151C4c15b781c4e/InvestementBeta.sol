// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Investement.sol";


/** 
* @author Formation.Fi.
* @notice Implementation of the contract InvestementBeta.
*/

contract InvestementBeta is Investement {
        constructor(address _admin,  address _safeHouse, address _stableToken, address _token,
        address _deposit, address _withdrawal) Investement( _admin, _safeHouse, _stableToken, _token,
         _deposit,  _withdrawal) {
        }
}