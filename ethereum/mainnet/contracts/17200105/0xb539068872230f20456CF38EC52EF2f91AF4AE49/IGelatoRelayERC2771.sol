// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./CallTypes.sol";

interface IGelatoRelayERC2771 {
    event LogCallWithSyncFeeERC2771(
        address indexed target,
        bytes32 indexed correlationId
    );

    function callWithSyncFeeERC2771(
        CallWithERC2771 calldata _call,
        address _feeToken,
        bytes calldata _userSignature,
        bool _isRelayContext,
        bytes32 _correlationId
    ) external;
}
