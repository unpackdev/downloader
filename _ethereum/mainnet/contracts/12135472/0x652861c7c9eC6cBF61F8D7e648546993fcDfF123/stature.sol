// SPDX-License-Identifier: GPL 3.0
pragma solidity ^0.7.3;

import "./ERC20.sol";

contract Stature is ERC20 {
    uint256 public INITIAL_SUPPLY = 23000000;

    constructor() ERC20("Stature", "STATURE") {
        _mint(msg.sender, INITIAL_SUPPLY * (10**uint256(decimals())));
    }

    function dummy() public pure returns (uint256 a) {
        return 23;
    }
}
