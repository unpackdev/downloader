// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./UpgradeableBeacon.sol";

import "./IBankNodeManager.sol";
import "./IBNPLProtocolConfig.sol";

contract BNPLProtocolConfig is IBNPLProtocolConfig {
    uint64 public override networkId;
    string public override networkName;

    IERC20 public override bnplToken;

    UpgradeableBeacon public override upBeaconBankNodeManager;

    UpgradeableBeacon public override upBeaconBankNode;
    UpgradeableBeacon public override upBeaconBankNodeLendingPoolToken;

    UpgradeableBeacon public override upBeaconBankNodeStakingPool;
    UpgradeableBeacon public override upBeaconBankNodeStakingPoolToken;

    UpgradeableBeacon public override upBeaconBankNodeLendingRewards;
    UpgradeableBeacon public override upBeaconBNPLKYCStore;

    IBankNodeManager public override bankNodeManager;

    constructor(
        uint64 _networkId,
        string memory _networkName,
        IERC20 _bnplToken,
        UpgradeableBeacon _upBeaconBankNodeManager,
        UpgradeableBeacon _upBeaconBankNode,
        UpgradeableBeacon _upBeaconBankNodeLendingPoolToken,
        UpgradeableBeacon _upBeaconBankNodeStakingPool,
        UpgradeableBeacon _upBeaconBankNodeStakingPoolToken,
        UpgradeableBeacon _upBeaconBankNodeLendingRewards,
        UpgradeableBeacon _upBeaconBNPLKYCStore,
        IBankNodeManager _bankNodeManager
    ) {
        networkId = _networkId;
        networkName = _networkName;

        bnplToken = _bnplToken;

        upBeaconBankNodeManager = _upBeaconBankNodeManager;

        upBeaconBankNode = _upBeaconBankNode;
        upBeaconBankNodeLendingPoolToken = _upBeaconBankNodeLendingPoolToken;

        upBeaconBankNodeStakingPool = _upBeaconBankNodeStakingPool;
        upBeaconBankNodeStakingPoolToken = _upBeaconBankNodeStakingPoolToken;

        upBeaconBankNodeLendingRewards = _upBeaconBankNodeLendingRewards;
        upBeaconBNPLKYCStore = _upBeaconBNPLKYCStore;

        bankNodeManager = _bankNodeManager;
    }
}
