// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./draft-ERC20Permit.sol";
import "./Multicall.sol";
import "./ERC1363.sol";

contract ZYM is
    ERC20("ZYM", "ZYM"),
    ERC20Permit("ZYM"),
    ERC1363,
    Multicall
{
    constructor(address initialHolder) {
        _mint(initialHolder, 100_000_000_000 ether);
    }
}
