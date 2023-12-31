// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./Interfaces.sol";

interface IStargateBaseV1 {
    struct StargateRedeemPayload {
        uint16 _dstChainId;
        uint256 _srcPoolId;
        uint256 _dstPoolId;
        address payable _refundAddress;
        uint256 _amountLP;
        uint256 _minAmountLD;
        bytes _to;
        IStargateRouter.lzTxObj _lzTxParams;
    }

    event RedeemLocal(uint16 _dstChainId, uint256 _srcPoolId, uint256 _amountLP);
    event RedeemRemote(uint16 _dstChainId, uint256 _srcPoolId, uint256 _amountLP);

    function redeemLocal(StargateRedeemPayload memory payload) external payable returns (bool);

    function redeemRemote(StargateRedeemPayload memory payload) external payable returns (bool);
}
