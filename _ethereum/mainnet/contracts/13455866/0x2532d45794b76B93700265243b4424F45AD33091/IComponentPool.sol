// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.6;

interface IComponentPool {
    function originSwap (
        address _origin,
        address _target,
        uint _originAmount,
        uint _minTargetAmount,
        uint _deadline
    ) external returns (
        uint256 tAmt_
    );
    function viewOriginSwap (
        address _origin,
        address _target,
        uint _originAmount
    ) external view returns (
        uint targetAmount_
    );
}