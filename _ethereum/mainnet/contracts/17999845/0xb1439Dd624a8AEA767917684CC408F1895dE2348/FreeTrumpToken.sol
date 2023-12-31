// SPDX-License-Identifier: MIT
import "./ERC20.sol";
/*
https://twitter.com/TrumpFree_Coin
https://t.me/freetrumpcoin_eth
https://freetrumpcoin.xyz/
*/

pragma solidity ^0.8.4;
contract FreeTrumpToken is ERC20, Ownable {
    constructor() ERC20("Free Trump", "FREETRUMP") {
        _mint(msg.sender, 7_010_000_000_000 * 10**uint(decimals()));
    }
}