// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./UpgradeableBeacon.sol";
import "./IERC20.sol";

import "./IBankNodeManager.sol";
import "./BNPLKYCStore.sol";

interface IBNPLProtocolConfig {
    function networkId() external view returns (uint64);

    function networkName() external view returns (string memory);

    function bnplToken() external view returns (IERC20);

    function upBeaconBankNodeManager() external view returns (UpgradeableBeacon);

    function upBeaconBankNode() external view returns (UpgradeableBeacon);

    function upBeaconBankNodeLendingPoolToken() external view returns (UpgradeableBeacon);

    function upBeaconBankNodeStakingPool() external view returns (UpgradeableBeacon);

    function upBeaconBankNodeStakingPoolToken() external view returns (UpgradeableBeacon);

    function upBeaconBankNodeLendingRewards() external view returns (UpgradeableBeacon);

    function upBeaconBNPLKYCStore() external view returns (UpgradeableBeacon);

    function bankNodeManager() external view returns (IBankNodeManager);
}
