// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Vault.sol";
import "./IERC20.sol";
import "./VaultBoardroom.sol";

contract ArthArthBoardroomV2 is VaultBoardroom {
    constructor(IERC20 cash_, Vault arthVault_)
        VaultBoardroom(cash_, arthVault_)
    {}
}
