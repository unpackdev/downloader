// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.17;

import "./Types.sol";

interface ITeller {
    function processBundle(
        Bundle calldata bundle
    )
        external
        returns (
            uint256[] memory opDigests,
            OperationResult[] memory opResults
        );

    function depositFunds(
        Deposit calldata deposit
    ) external returns (uint128 merkleIndex);

    function requestAsset(
        EncodedAsset calldata encodedAsset,
        uint256 value
    ) external;
}
