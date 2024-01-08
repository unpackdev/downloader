// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "./SafeERC20.sol";
import "./SafeMath.sol";

contract EarlyContributorVesting{
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    uint constant MIN_PERIOD = 2629743;
    IERC20 private Punk;
    
    bool private _initialize = false;
    address private admin;

    uint private _startTimestamp;
    uint private _count;
    uint private _released;
    address private _to;

    modifier OnlyAdmin(){
        require( msg.sender == admin );
        _;
    }

    constructor( ) payable {
        Punk = IERC20( address( 0x558985b6eE1E4F5146060B1A2A56fd5c8FFb9C68 ) );
        admin = msg.sender;
    }

    function setInfomation( address to_, uint count_ ) public OnlyAdmin {
        require( !_initialize );
        require( count_ > 0 );
        _to                 = to_;
        _startTimestamp     = block.timestamp;
        _count              = count_;
        _initialize         = true;
    }

    function claim() public {
        require( _initialize );
        require( _startTimestamp <= _currentTimestamp());
        uint ableAmount = claimable();
        Punk.safeTransfer( _to, ableAmount );
        _released += ableAmount;
    }

    function released() public view returns ( uint ){
        return _released;
    }

    function totalBalance() public view returns ( uint ){
        return Punk.balanceOf( address( this ) ).add( _released );
    }

    function to() public view returns ( address ){
        return _to;
    }

    function claimable() public view returns( uint ){
        if( _startTimestamp == 0 ) return 0;
        if( Punk.balanceOf( address( this ) ) == 0 ) return 0;
        
        uint count = _currentTimestamp().sub( _startTimestamp ).div( MIN_PERIOD );
        if( count > _count ) count = _count;
        return totalBalance().mul( count ).div( _count ).sub( _released );
    }

    function _currentTimestamp() private view returns( uint ){
        return block.timestamp;
    }

}
