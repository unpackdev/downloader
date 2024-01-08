// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Attestor
 * @dev Store & retrieve value in a variable
 */
contract Attestor {

     string treeRoot;
 
     /**
     * @dev Store value in variable
     * @param x value to store
     */
     function sendHash(string memory x) public {
         treeRoot = x;
     }
}