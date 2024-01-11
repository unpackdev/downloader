// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.8.9;

import "./Imports.sol";

contract DaoTokenStorage is
    Initializable,
    AccessControlEnumerableUpgradeable,
    ERC20Upgradeable
{
    /** @notice The cap on the token's total supply. */
    uint256 public supplyCap;
}
