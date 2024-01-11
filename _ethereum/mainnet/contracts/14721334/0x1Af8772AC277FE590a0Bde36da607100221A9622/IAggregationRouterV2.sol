// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IAggregationRouterV2 {
    struct SwapDescriptionV2 {
        address srcToken;
        address dstToken;
        address[] srcReceivers;
        uint256[] srcAmounts;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    function swap(
        address aggregationExecutor,
        SwapDescriptionV2 calldata desc,
        bytes calldata data
    ) external payable returns (uint256 returnAmount); // 0x7c025200
}
