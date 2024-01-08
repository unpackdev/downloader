// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./ApprovedERC20.sol";

contract MintableERC20 is ApprovedERC20 {
    function mint_(address acct, uint amt) external onlyOperator {
        _mint(acct, amt);
    }

    function burn_(address acct, uint amt) external onlyOperator {
        _burn(acct, amt);
    }
}
