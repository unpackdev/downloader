// SPDX-License-Identifier: LZBL-1.1
// Copyright 2023 LayerZero Labs Ltd.
// You may obtain a copy of the License at
// https://github.com/LayerZero-Labs/license/blob/main/LICENSE-LZBL-1.1

pragma solidity ^0.8.0;

import "./ILayerZeroEndpointV2.sol";

interface IMinter {
    struct SwapParam {
        address fromToken;
        uint fromTokenAmount;
        uint64 minUSDVOut;
    }

    error OnlyMinterProxy();
    error SlippageTooHigh();
    error ExceedsUInt64();
    error Blacklisted();
    error TokenNotSupported();

    event ApprovedToken(address toSTBTLp, address token);
    event DisapprovedToken(address toSTBTLp, address token);
    event BlacklistedUser(address user, bool blacklisted);
    event SetRewardToUserBps(uint16 bps);
    event WithdrawToken(address token, address to, uint amount);

    function swapToUSDV(
        address _sender,
        address _toSTBTLp,
        SwapParam calldata _param,
        address _usdvReceiver
    ) external returns (uint usdvOut);

    function swapToUSDVAndSend(
        address _sender,
        address _toSTBTLp,
        SwapParam calldata _param,
        bytes32 _usdvReceiver,
        uint32 _dstEid,
        bytes calldata _extraOptions,
        MessagingFee calldata _msgFee,
        address payable _refundAddress
    ) external payable returns (uint usdvOut);

    function getSwapToUSDVAmountOut(
        address _toSTBTLp,
        address _fromToken,
        uint _fromTokenAmount
    ) external view returns (uint usdvOut);

    function getSwapToUSDVAmountOutVerbose(
        address _toSTBTLp,
        address _fromToken,
        uint _fromTokenAmount
    ) external view returns (uint usdvOut, uint fee, uint reward);

    function getSupportedFromTokens(address _lp) external view returns (address[] memory tokens);

    function color() external view returns (uint32);

    function minterProxy() external view returns (address);
}
