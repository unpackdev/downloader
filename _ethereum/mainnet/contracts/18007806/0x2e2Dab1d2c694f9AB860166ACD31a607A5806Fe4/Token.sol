// SPDX-License-Identifier: MIT
import "./ERC20.sol";


/*
https://pepewaifutoken.xyz/
https://t.me/pepewaifutoken
https://twitter.com/PepeWaifuCoin
*/

pragma solidity ^0.8.4;
contract Token is ERC20, Ownable {
    constructor() ERC20("Pepe Waifu", "PEPEWAIFU") {
        _mint(msg.sender, 9_001_000_000_000 * 10**uint(decimals()));
    }
}