// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Token.sol";

/** 
* @author Formation.Fi.
* @notice Implementation of the contract TokenAlpha.
*/

contract TokenAlpha is Token {
    constructor() Token ("ALPHA", "ALPHA") {
    }
}