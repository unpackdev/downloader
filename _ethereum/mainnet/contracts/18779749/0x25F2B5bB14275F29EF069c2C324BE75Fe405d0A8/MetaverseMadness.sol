// SPDX-License-Identifier: MIT
import "./ERC20.sol";

//Website: https://metaversusai.com/
//Twitter: https://twitter.com/Metaversus_ai
//Telegram: https://t.me/MetaVersuss_Bot

pragma solidity ^0.8.0;

contract MetaverseMadness is ERC20 {
    constructor(uint256 _totalSupply) ERC20("MetaverseMadness", "Metaversus") {
        _mint(msg.sender, _totalSupply);
    }
}
