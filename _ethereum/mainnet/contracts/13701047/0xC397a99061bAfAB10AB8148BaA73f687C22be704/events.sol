// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

contract Events {
    event LogClaim(uint256 amt, uint256 getId, uint256 setId);
    event LogStake(uint256 amt, uint256 getId, uint256 setId);
    event LogCooldown();
    event LogRedeem(uint256 amt, uint256 getId, uint256 setId);
    event LogDelegate(
        address delegatee,
        bool delegateAave,
        bool delegateStkAave,
        uint8 aaveDelegationType,
        uint8 stkAaveDelegationType
    );
}
