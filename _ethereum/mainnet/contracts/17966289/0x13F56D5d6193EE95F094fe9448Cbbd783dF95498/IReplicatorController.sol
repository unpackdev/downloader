// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IReplicatorController {
    function pagesMinted(uint256 replicatorId) external view returns (uint256);

    function estimateFee(
        uint16 functionType,
        uint16 dstChainId,
        bytes memory toAddress,
        uint256 replicatorId,
        uint256 amount,
        bool useZro,
        bytes memory adapterParams
    ) external view returns (uint256 nativeFee, uint256 zroFee);
    function estimateBatchFee(
        uint16 functionType,
        uint16 dstChainId,
        bytes memory toAddress,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bool useZro,
        bytes memory adapterParams
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    function replicate(uint256 replicatorId, uint256 amount) external;
    function replicateFrom(
        uint256 replicatorId,
        uint256 amount,
        uint16 dstChainId,
        bytes memory toAddress,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes memory adapterParams
    ) external payable;
}