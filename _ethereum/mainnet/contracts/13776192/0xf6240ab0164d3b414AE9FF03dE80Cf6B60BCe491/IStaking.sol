// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IStaking {
    function stake( uint _amount, address _recipient, bool _wrap ) external returns ( uint );

    function claim ( address _recipient ) external returns ( uint );

    function forfeit() external returns ( uint );

    function toggleLock() external;

    function unstake( uint _amount, bool _trigger ) external returns ( uint );

    function rebase() external;

    function index() external view returns ( uint );

    function contractBalance() external view returns ( uint );

    function totalStaked() external view returns ( uint );

    function supplyInWarmup() external view returns ( uint );
}