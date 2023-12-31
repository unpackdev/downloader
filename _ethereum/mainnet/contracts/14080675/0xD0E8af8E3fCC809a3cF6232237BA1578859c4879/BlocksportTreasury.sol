
// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "./Initializable.sol";

import "./AdminRole.sol";
import "./CollateralManagement.sol";
import "./WithdrawFromEscrow.sol";

/**
 * @notice The Blocksport treasury which collects fees generated by the market.
 * @dev The core responsibility of this contract is collecting fees.
 */
contract BlocksportTreasury is
    AdminRole,
    CollateralManagement,
    WithdrawFromEscrow
{
    function initialize(address admin) public initializer {
        AdminRole._initializeAdminRole(admin);
    }
}
