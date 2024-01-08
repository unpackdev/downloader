// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./SProtection.sol";

function _getProtectionPayload(
    bytes32 _taskHash,
    bytes memory _data,
    bytes memory _offChainData
) pure returns (ProtectionPayload memory) {
    ProtectionPayload memory protectionPayload;

    protectionPayload.taskHash = _taskHash;

    (
        protectionPayload.wantedHealthFactor,
        protectionPayload.minimumHealthFactor,
        protectionPayload.onBehalfOf
    ) = abi.decode(_data, (uint256, uint256, address));

    // Stack too deep hack
    // Cannot do it in one time.
    // Off chain data decoding.
    (
        protectionPayload.colToken,
        protectionPayload.debtToken,
        protectionPayload.rateMode,
        protectionPayload.amtToFlashBorrow,
        protectionPayload.amtOfDebtToRepay
    ) = abi.decode(
        _offChainData,
        (address, address, uint256, uint256, uint256)
    );

    (
        ,
        ,
        ,
        ,
        ,
        protectionPayload.protectionFeeInETH,
        protectionPayload.swapActions,
        protectionPayload.swapDatas,
        protectionPayload.subBlockNumber,
        protectionPayload.isPermanent
    ) = abi.decode(
        _offChainData,
        (
            address,
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            address[],
            bytes[],
            uint256,
            bool
        )
    );

    return protectionPayload;
}
