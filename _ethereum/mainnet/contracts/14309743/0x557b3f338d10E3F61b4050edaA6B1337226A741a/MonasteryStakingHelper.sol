// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./IERC20.sol";

interface IStaking {
    function stake( uint _amount, address _recipient ) external returns ( bool );
    function claim( address _recipient ) external;
}

contract MonasteryStakingHelper {

    address public immutable staking;
    address public immutable MONK;

    constructor ( address _staking, address _MONK ) {
        require( _staking != address(0) );
        staking = _staking;
        require( _MONK != address(0) );
        MONK = _MONK;
    }

    function stake( uint _amount ) external {
        IERC20( MONK ).transferFrom( msg.sender, address(this), _amount );
        IERC20( MONK ).approve( staking, _amount );
        IStaking( staking ).stake( _amount, msg.sender );
        IStaking( staking ).claim( msg.sender );
    }
}
