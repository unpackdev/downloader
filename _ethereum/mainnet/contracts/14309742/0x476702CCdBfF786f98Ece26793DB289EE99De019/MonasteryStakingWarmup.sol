// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;


import "./IERC20.sol";


contract MonasteryStakingWarmup {

    address public immutable staking;
    address public immutable ZEN;

    constructor ( address _staking, address _ZEN ) {
        require( _staking != address(0) );
        staking = _staking;
        require( _ZEN != address(0) );
        ZEN = _ZEN;
    }

    function retrieve( address _staker, uint _amount ) external {
        require( msg.sender == staking );
        IERC20( ZEN ).transfer( _staker, _amount );
    }
}
