// SPDX-License-Identifier: MIT
import "./ERC20.sol";

//Website: https://blackdiamondai.com/
//Twitter: https://twitter.com/bdiamondai
//Telegram: https://t.me/black_diamond_ai_bot

pragma solidity ^0.8.0;

contract BlackDiamondAi is ERC20 {
    constructor(uint256 _totalSupply) ERC20("BlackDiamondAi", "DiamondAi") {
        _mint(msg.sender, _totalSupply);
    }
}
