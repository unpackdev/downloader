// SPDX-License-Identifier: AGPL-3.0-or-later


pragma solidity 0.7.5;

import "./IERC20.sol";

contract StakingWarmup {

    address public immutable staking;
    address public immutable sGaas;

    constructor ( address _staking, address _sGaas ) {
        require( _staking != address(0) );
        staking = _staking;
        require( _sGaas != address(0) );
        sGaas = _sGaas;
    }

    function retrieve( address _staker, uint _amount ) external {
        require( msg.sender == staking );
        IERC20( sGaas ).transfer( _staker, _amount );
    }
}