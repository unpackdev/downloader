// SPDX-License-Identifier: MIT

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.9;

import "./ERC20.sol";

contract Unibit is ERC20 {

    address public immutable fund;

    constructor(address fund_) ERC20("Unibit", "UBT") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
        fund = fund_;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        uint tax = (amount / 100) * 5; // 5% tax

        super._transfer(sender, recipient, amount - tax);
        super._transfer(sender, fund, tax);
    }
}