// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./RangoMultichainModels.sol";

interface IRangoMultichain {
    function multichainBridge(
        RangoMultichainModels.MultichainBridgeType _actionType,
        address _fromToken,
        address _underlyingToken,
        uint _inputAmount,
        address multichainRouter,
        address _receiverAddress,
        uint _receiverChainID
    ) external payable;

}