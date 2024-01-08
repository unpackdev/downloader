// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;


import "./IERC20.sol";


contract AxeStakingWarmup {

    address public immutable staking;
    address public immutable sAXE;

    constructor ( address _staking, address _sAXE ) {
        require( _staking != address(0) );
        staking = _staking;
        require( _sAXE != address(0) );
        sAXE = _sAXE;
    }

    function retrieve( address _staker, uint _amount ) external {
        require( msg.sender == staking );
        IERC20( sAXE ).transfer( _staker, _amount );
    }
}
