// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./KeeperCompatible.sol";
import "./IFeeDistributor.sol";
import "./IFeeCollector.sol";

contract BendKeeper is KeeperCompatibleInterface {
    uint256 public constant DAY = 86400;
    IFeeDistributor public feeDistributor;
    IFeeCollector public feeCollector;
    uint256 public nextDistributeTime;

    constructor(address _feeDistributorAddr, address _feeCollector) {
        feeDistributor = IFeeDistributor(_feeDistributorAddr);
        feeCollector = IFeeCollector(_feeCollector);
        nextDistributeTime = (block.timestamp / DAY) * DAY + DAY;
    }

    function checkUpkeep(bytes calldata)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory)
    {
        upkeepNeeded = block.timestamp >= nextDistributeTime;
    }

    function performUpkeep(bytes calldata) external override {
        if (block.timestamp >= nextDistributeTime) {
            feeCollector.collect();
            feeDistributor.distribute();
            nextDistributeTime += DAY;
        }
    }
}
