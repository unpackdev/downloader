// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./IVault.sol";

/* solium-disable */
contract MockTimeLock {
    // test helpers
    function _setTimeLock_(address _vault, address _timeLock) external {
        IVault(_vault).setTimeLock(_timeLock);
    }

    function _approveStrategy_(address _vault, address _strategy) external {
        IVault(_vault).approveStrategy(_strategy);
    }
}
