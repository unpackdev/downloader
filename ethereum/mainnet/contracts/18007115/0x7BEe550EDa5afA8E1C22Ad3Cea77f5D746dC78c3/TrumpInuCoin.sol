// SPDX-License-Identifier: MIT
import "./ERC20.sol";


/*
https://twitter.com/trumpinuxyz
https://t.me/trumpinuxyz
https://trumpinu.xyz
*/

pragma solidity ^0.8.4;
contract TrumpInuCoin is ERC20, Ownable
{
    constructor() ERC20("Trump Inu", "TRUMPINU")
    {
        _mint(msg.sender, 8_001_000_000_000 * 10**uint(decimals()));
    }

    function decimals() public view virtual override returns (uint8)
    {
        return 18;
    }
}