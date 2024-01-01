// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IExecutor {
    function execute(
        uint256 _id,
        uint256 _for,
        uint256 _against,
        uint256 _quorum
    ) external;
}
