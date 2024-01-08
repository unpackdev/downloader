// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface ITreasury {
    // deposit to the treasury
    function deposit( uint _amount, address _token, uint _profit ) external returns ( uint send_ );

    // withdraw from the treasury
    function manage( address _token, uint _amount ) external;

    // return the valuation of the asset
    function valueOf( address _token, uint _amount ) external view returns ( uint value_ );
}
