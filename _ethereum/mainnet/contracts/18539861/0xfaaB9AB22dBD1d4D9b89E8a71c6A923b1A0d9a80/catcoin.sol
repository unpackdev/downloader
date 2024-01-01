// SPDX-License-Identifier: MIT

import "./ERC20.sol";

pragma solidity ^0.8.4;

/*

cat.

https://caterc20.xyz
https://twitter.com/catonethereum
https://t.me/catethportal

*/

contract catcoin is ERC20
{
    constructor() ERC20 ("cat", "cat")
    {
        _mint(msg.sender,
            5_010_000_000_000
            * 10**uint(decimals()));
    }
}