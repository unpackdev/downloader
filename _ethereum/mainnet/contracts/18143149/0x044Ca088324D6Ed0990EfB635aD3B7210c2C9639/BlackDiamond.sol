// SPDX-License-Identifier: MIT


// Telegram:https://t.me/theblackdiamondtoken
// Twitter: https://twitter.com/bdteth777
// Website: https://blackdiamondtoken.tech/


import "./ERC20.sol";


pragma solidity ^0.8.0;

contract BlackDiamond is ERC20 {
    constructor(uint256 _totalSupply) ERC20("BlackDiamond", "BDT") {
        _mint(msg.sender, _totalSupply);
    }
}
