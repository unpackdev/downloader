// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract nestCreator {
    function createNest(address token) external returns(address nest){
        nest = address(new Nest(token));
    }
}

contract Nest {
    //Contract cannot do anything so no removal of tokens can happen
    address public Token;
    constructor(address _Token) {
        Token = _Token;
    } 
}