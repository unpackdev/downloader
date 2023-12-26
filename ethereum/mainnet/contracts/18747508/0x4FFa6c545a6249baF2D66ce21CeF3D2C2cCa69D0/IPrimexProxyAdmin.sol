// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;
import "./UpgradeableBeacon.sol";

interface IPrimexProxyAdmin {
    function upgradeBeacon(UpgradeableBeacon beacon, address implementation) external;

    function changeBeaconProxyAdmin(UpgradeableBeacon beacon, address newAdmin) external;
}
