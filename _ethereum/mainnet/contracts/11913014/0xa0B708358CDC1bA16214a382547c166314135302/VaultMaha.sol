// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Vault.sol";
import "./IERC20.sol";

contract VaultMaha is Vault {
    constructor(IERC20 share, uint256 lockIn) Vault(share, lockIn) {}
}
