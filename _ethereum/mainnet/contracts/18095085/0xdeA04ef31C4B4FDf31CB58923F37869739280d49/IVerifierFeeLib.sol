// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

import "./IVerifier.sol";

interface IVerifierFeeLib {
    struct FeeParams {
        address priceFeed;
        uint32 dstEid;
        uint64 confirmations;
        address sender;
        uint64 quorum;
        uint16 defaultMultiplierBps;
    }

    function getFeeOnSend(
        FeeParams memory _params,
        IVerifier.DstConfig memory _dstConfig,
        bytes memory _options
    ) external payable returns (uint fee);

    function getFee(
        FeeParams calldata _params,
        IVerifier.DstConfig calldata _dstConfig,
        bytes calldata _options
    ) external view returns (uint fee);
}
