// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./KeeperCompatible.sol";
import "./IFeeDistributor.sol";

contract BendKeeper is KeeperCompatibleInterface {
    uint256 public interval;
    IFeeDistributor public feeDistributor;

    constructor(uint256 _interval, address _feeDistributorAddr) {
        interval = _interval;
        feeDistributor = IFeeDistributor(_feeDistributorAddr);
    }

    function checkUpkeep(bytes calldata)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory)
    {
        upkeepNeeded =
            (block.timestamp - feeDistributor.lastDistributeTime()) > interval;
    }

    function performUpkeep(bytes calldata) external override {
        if (
            (block.timestamp - feeDistributor.lastDistributeTime()) > interval
        ) {
            feeDistributor.distribute();
        }
    }
}
