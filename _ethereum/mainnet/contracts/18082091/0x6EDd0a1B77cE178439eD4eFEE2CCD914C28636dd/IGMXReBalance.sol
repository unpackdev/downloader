// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;
pragma experimental "ABIEncoderV2";

import "./IJasperVault.sol";
import "./IGMXAdapter.sol";

interface IGMXReBalance {
    function _rebalanceGMX(
        IJasperVault jasperVault,
        GMXInfo memory gmxInfos
    ) external;

    struct GMXInfo {
        string _integrationName;
        IGMXAdapter.SwapData[] swapDatas;
        IGMXAdapter.IncreasePositionRequest[] increasePositionRequests;
        IGMXAdapter.DecreasePositionRequest[] decreasePositionRequest;
        IGMXAdapter.IncreaseOrderData[] increaseOrderDatas;
        IGMXAdapter.DecreaseOrderData[] decreaseOrderDatas;
        IGMXAdapter.StakeGMXData[] stakeGMXDatas;
        IGMXAdapter.StakeGLPData[] stakeGLPDatas;
    }
}
