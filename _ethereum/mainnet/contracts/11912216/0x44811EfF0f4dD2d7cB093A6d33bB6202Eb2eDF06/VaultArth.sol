// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Vault.sol";
import "./IERC20.sol";

contract VaultArth is Vault {
    constructor(IERC20 cash_, uint256 lockIn_) Vault(cash_, lockIn_) {}
}
