// SPDX-License-Identifier: AGPL-3.0-or-later


pragma solidity 0.7.5;

import "./IERC20.sol";
import "./IStaking.sol";

contract StakingHelper {

    address public immutable staking;
    address public immutable Gaas;

    constructor ( address _staking, address _Gaas ) {
        require( _staking != address(0) );
        staking = _staking;
        require( _Gaas != address(0) );
        Gaas = _Gaas;
    }

    function stake( uint _amount) external {
        IERC20( Gaas ).transferFrom( msg.sender, address(this), _amount );
        IERC20( Gaas ).approve( staking, _amount );
        IStaking( staking ).stake( _amount, msg.sender );
        IStaking( staking ).claim( msg.sender );
    }
}