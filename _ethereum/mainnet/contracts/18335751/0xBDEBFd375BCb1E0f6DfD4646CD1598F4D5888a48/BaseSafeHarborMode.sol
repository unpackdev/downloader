// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./Context.sol";
import "./BaseAccessControl.sol";
import "./IBaseSafeHarborMode.sol";

abstract contract BaseSafeHarborMode is Context, IBaseSafeHarborMode, BaseAccessControl {
    bool public SAFE_HARBOR_MODE_ENABLED;

    function disableSafeHarborMode() external onlyAdmins {
        _setSafeHarborMode(false);
    }

    function enableSafeHarborMode() external onlyWhitelisted {
        _setSafeHarborMode(true);
    }

    function _setSafeHarborMode(bool _enabled) internal {
        SAFE_HARBOR_MODE_ENABLED = _enabled;
        emit SafeHarborModeUpdate(_msgSender(), _enabled);
    }
}
