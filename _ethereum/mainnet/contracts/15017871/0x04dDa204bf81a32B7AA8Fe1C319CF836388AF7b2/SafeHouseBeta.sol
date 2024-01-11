// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./SafeHouse.sol";

/** 
* @author Formation.Fi.
* @notice Implementation of the contract SafeHouseBeta.
*/

contract SafeHouseBeta is SafeHouse{
        constructor(address _assets, address _admin) SafeHouse(_assets, _admin) {
    }
}