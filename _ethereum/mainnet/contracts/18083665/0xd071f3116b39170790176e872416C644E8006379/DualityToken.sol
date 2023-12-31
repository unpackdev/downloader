// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// #####    ##   ##    ###    ####      ######   # ##### ###  ###
//  ## ##   ##   ##   ## ##    ##         ##    ## ## ##  ##  ##
//  ##  ##  ##   ##  ##   ##   ##         ##       ##      ####
//  ##  ##  ##   ##  ##   ##   ##         ##       ##       ##
//  ##  ##  ##   ##  #######   ##         ##       ##       ##
//  ## ##   ##   ##  ##   ##   ##  ##     ##       ##       ##
// #####     #####   ##   ##  #######   ######    ####     ####


// Twiiter：https://twitter.com/DualityNFT_


/*The Duality collection, comprised of 1000 unique pieces, is a testament to my belief and artistic philosophy that all things should exist. 
In designing the faces, forms, and micro-expressions, 
I have cast aside the balance between beauty and ugliness. 
Perhaps you may find some of these visages unappealing, 
but I insist upon their existence — they are as real and valid as any other.
I look forward to sharing this journey with you and exploring this social experiment together.
*/
contract DualityToken {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint8 public decimals;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        name = "Start exploring Duality";
        symbol = "Duality";
        decimals = 18;
        totalSupply = 100000000 * (10**uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
}