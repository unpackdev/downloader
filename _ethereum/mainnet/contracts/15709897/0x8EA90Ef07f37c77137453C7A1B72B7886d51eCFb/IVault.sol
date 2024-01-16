// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IVault {
    function ackWithdraw(
        address _user,
        uint256 _pid,
        uint256 _amount,
        uint64 _nonce
    ) external;

    function ackEmergencyWithdraw(
        address _user,
        uint256 _pid,
        uint64 _nonce
    ) external;
}
