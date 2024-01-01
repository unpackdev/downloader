// SPDX-License-Identifier: MIT
import "./ERC20.sol";
pragma solidity ^0.8.4;

/*

Twitter: https://twitter.com/HayPepeETH
Telegram: https://t.me/HayPepe
Website: https://haypepe.xyz

*/

contract HayPepeToken is ERC20, Ownable {
    constructor () ERC20 ("HayPepe", "HAYPEPE") {
        _mint(msg.sender, 5_010_000_000_000 * 10**uint(decimals()));
    }
}