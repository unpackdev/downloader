// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

// solhint-disable-next-line contract-name-camelcase
interface IBaseSafeHarborMode {
    event SafeHarborModeUpdate(address indexed actor, bool indexed isEnabled);

    function SAFE_HARBOR_MODE_ENABLED() external view returns (bool);

    function enableSafeHarborMode() external;

    function disableSafeHarborMode() external;
}
