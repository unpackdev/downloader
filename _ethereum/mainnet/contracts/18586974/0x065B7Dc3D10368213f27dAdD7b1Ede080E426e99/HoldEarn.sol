/**
        BUY, HOLD, EARN, BURN!
        Telegram: https://t.me/buyholdearn
        Website: http://buyholdearn.com
        X: https://twitter.com/buyholdearn
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";

contract HoldEarn is ERC20, Ownable {
    constructor(address initialOwner)
        ERC20("HOLD", "EARN")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}