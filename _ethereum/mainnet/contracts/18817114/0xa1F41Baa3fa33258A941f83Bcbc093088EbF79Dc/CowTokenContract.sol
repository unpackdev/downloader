// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "./ERC20.sol";

// /**
//  * COW TOKEN  COW TOKEN  COW TOKEN  COW TOKEN  COW TOKEN  COW TOKEN  COW TOKEN  COW TOKEN  COW TOKEN  COW TOKEN  COW TOKEN
//  *
//  * Introducing $COW - It's a cow token
//  *
//  * Here's some more info on the cow token. 
//  *
//  * Website: cowtoken.org
//  * Twitter: https://twitter.com/ItsACowToken
//  *
//  * COW TOKEN  COW TOKEN  COW TOKEN  COW TOKEN  COW TOKEN  COW TOKEN  COW TOKEN  COW TOKEN  COW TOKEN  COW TOKEN  COW TOKEN
//  */

contract CowTokenContract is ERC20 {
    /**
     * This is the contructor for the Cow token
     */
    constructor()
        ERC20("A Cow Token", "COW")
    {
        // this mints the cow token (100 million of them)
        _mint(msg.sender, 100_000_000 * 1e18);
    }
}
