// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "./RollupTypes.sol";

interface ISettle {
    function settle(
        RollupInfo memory rollupInfo,
        bytes calldata data,
        bytes32[] calldata proof
    ) external;
}
