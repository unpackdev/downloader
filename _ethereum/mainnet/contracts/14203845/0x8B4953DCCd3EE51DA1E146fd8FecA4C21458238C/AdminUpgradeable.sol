// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "AdminBase.sol";

contract AdminUpgradeable is AdminBase {
    /**
     * @dev This is to avoid breaking contracts inheriting from `AdminUpgradeable
     * in case we need to add more variables to the admin contract, although unlikely
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     * for more details
     */
    uint256[50] private __gap;

    function _initializeAdmin(address _admin) internal {
        _addAdmin(_admin);
    }
}
