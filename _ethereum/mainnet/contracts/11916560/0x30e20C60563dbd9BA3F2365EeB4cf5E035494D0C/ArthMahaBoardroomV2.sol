// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Vault.sol";
import "./IERC20.sol";
import "./VestedVaultBoardroom.sol";

contract ArthMahaBoardroomV2 is VestedVaultBoardroom {
    constructor(
        IERC20 cash_,
        Vault mahaVault_,
        uint256 vestFor_
    ) VestedVaultBoardroom(cash_, mahaVault_, vestFor_) {}
}
