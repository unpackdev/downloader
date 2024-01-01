// SPDX-License-Identifier: MIT
import "./ERC20.sol";
pragma solidity ^0.8.4;

/*

https://twitter.com/HayPepeETH
https://t.me/HayPepe
https://haypepe.xyz

*/

contract HayPepeCoin is ERC20 {
    constructor () ERC20 ("HayPepe", "HAYPEPE") {
        _mint(msg.sender, 5_010_000_000_000 * 10**uint(decimals()));
    }
}