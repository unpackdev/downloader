// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IQAirdrop {
    function withdrawLockedQStk(
        address _recipient,
        uint256 _qstkAmount,
        bytes memory _signature
    ) external returns (uint256);
}
