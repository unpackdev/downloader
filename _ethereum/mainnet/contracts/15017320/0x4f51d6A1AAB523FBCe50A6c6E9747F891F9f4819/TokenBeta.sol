// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Token.sol";

/** 
* @author Formation.Fi.
* @notice Implementation of the contract TokenBeta.
*/

contract TokenBeta is Token {
    constructor() Token ("BETA", "BETA") {
    }
}