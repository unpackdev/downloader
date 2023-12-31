// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";

contract KakashiCoin is ERC20, Ownable {
    constructor() ERC20("KakashiCoin", "KAKASHI") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}