// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract SuperproToken is ERC20 {
    constructor(
        address gnosisSafeAccount,
        uint256 supply,
        string memory ticker,
        string memory description
    ) ERC20(description, ticker) {
        _mint(gnosisSafeAccount, supply);
    }
}
