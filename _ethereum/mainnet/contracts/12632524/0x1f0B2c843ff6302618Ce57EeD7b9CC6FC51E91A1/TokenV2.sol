// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Token.sol";

// Upgraded version of main token contract for use in tests
contract TokenV2 is Token {
    // Test constant
    string public constant _string = "constant string from tokenv2";
    // Test variable
    uint8 public _x;

    // Emitted when _x variable changes
    event XChanged(uint8 new_x);

    // Constructor for upgradeable contract
    function initialize(
        string memory name,
        string memory symbol,
        string memory version,
        uint256 total_coins
    ) public override initializer {
        Token.initialize(name, symbol, version, total_coins);
    }

    // Update _x variable
    function updateX(uint8 x) public ownerOnly {
        _x = x;
        emit XChanged(_x);
    }
}
