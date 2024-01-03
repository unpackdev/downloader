// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract UsedSOL is ERC20 {
    address public owner;
    constructor() ERC20("UsedSOL", "UsedSOL") {
        _mint(msg.sender, 100_000_000_000 * 10 ** 18);
        owner = msg.sender;
    }
}