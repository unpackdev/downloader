// SPDX-License-Identifier: MIT
import "./ERC20.sol";

/*
https://t.me/HGPKW69I
https://twitter.com/HGPKW69I
https://hgpkw69i.lol/
*/

pragma solidity ^0.8.4;
contract HarryToken is ERC20, Ownable
{
    constructor () ERC20 ("HarryGayPotterKanyeWest69Inu", "UNISWAP")
    {
        _mint(msg.sender, 4_010_000_000_000 * 10**uint(decimals()));
    }
}