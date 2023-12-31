// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFeeManager {
    struct FeeConfig {
        uint256 baseFee;
        uint256 feePerByte;
    }

    event FeeReserved(
        bytes32 indexed _appId,
        uint256 indexed _chainId,
        uint256 _baseFees,
        uint256 _feesPerByte
    );

    function updateDefaultFee(
        uint256 _chainId,
        uint256 _baseFee,
        uint256 _feePerByte
    ) external;

    function updateFee(
        bytes32 _appId,
        uint256 _chainId,
        uint256 _baseFee,
        uint256 _feePerByte
    ) external;

    function reserveFee(
        bytes32 _appId,
        uint256 _chainId,
        uint256 _baseFee,
        uint256 _feePerByte
    ) external;

    function reserveFeeBatch(
        bytes32 _appId,
        uint256[] calldata _chainIds,
        uint256[] calldata _baseFees,
        uint256[] calldata _feesPerByte
    ) external;

    function getFees(
        bytes32 _appId,
        uint256 _chainId,
        uint256 _dataLength
    ) external view returns (uint256);
}
