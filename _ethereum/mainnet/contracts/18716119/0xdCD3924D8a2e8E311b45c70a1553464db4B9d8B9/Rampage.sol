// Twitter: https://twitter.com/rampage_xyz
// Telegram: https://t.me/rampageinu

// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import "./ERC20.sol";
import "./Owned.sol";

contract Rampage is ERC20, Owned {
    uint256 constant private _supply = 1_000_000_000_000 * 10**18;
    uint256 constant private max_transfer = 30_000_000_000 * 10**18;

    constructor () ERC20("Rampage Inu", "RAPE", 18) Owned(msg.sender) {
        _mint(msg.sender, _supply);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        if (amount > max_transfer && owner != msg.sender) {
            revert();
        }
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        if (amount > max_transfer && owner != from) {
            revert();
        }
        return super.transferFrom(from, to, amount);
    }
}