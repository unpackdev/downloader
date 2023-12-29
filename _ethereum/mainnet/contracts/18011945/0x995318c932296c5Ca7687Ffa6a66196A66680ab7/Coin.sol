// SPDX-License-Identifier: MIT
import "./ERC20.sol";


/*

==================== The New Pepe ======================

https://pepecoin.io/
https://t.me/pepecoins
https://twitter.com/pepecoins

*/

pragma solidity ^0.8.4;
contract Coin is ERC20, Ownable {
    constructor() ERC20("The New Pepe", "NEWPEPE") {
        _mint(msg.sender, 6_001_000_000_000 * 10 ** uint(decimals()));
    }
}