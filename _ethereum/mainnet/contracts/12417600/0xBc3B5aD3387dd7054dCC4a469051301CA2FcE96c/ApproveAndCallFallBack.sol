// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ApproveAndCallFallBack {
    function receiveApproval(
        address from,
        uint256 tokens,
        address token,
        bytes memory data
    ) external;
}

