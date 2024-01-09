// SPDX-License-Identifier: AGPL-3.0-or-later


pragma solidity 0.7.5;

import "./IERC20.sol";
import "./SafeMath.sol";

contract GaasCirculatingSupplyConrtact {
    using SafeMath for uint;

    bool public isInitialized;

    address public Gaas;
    address public owner;
    address[] public nonCirculatingGaasAddresses;

    constructor() {        
        owner = msg.sender;
    }

    function initialize( address _Gaas ) external returns ( bool ) {
        require( msg.sender == owner, "caller is not owner" );
        require( isInitialized == false );

        Gaas = _Gaas;

        isInitialized = true;

        return true;
    }

    function GaasCirculatingSupply() external view returns ( uint ) {
        uint _totalSupply = IERC20( Gaas ).totalSupply();

        uint _circulatingSupply = _totalSupply.sub( getNonCirculatingGaas() );

        return _circulatingSupply;
    }

    function getNonCirculatingGaas() public view returns ( uint ) {
        uint _nonCirculatingGaas;

        for( uint i=0; i < nonCirculatingGaasAddresses.length; i = i.add( 1 ) ) {
            _nonCirculatingGaas = _nonCirculatingGaas.add( IERC20( Gaas ).balanceOf( nonCirculatingGaasAddresses[i] ) );
        }

        return _nonCirculatingGaas;
    }

    function setNonCirculatingGaasAddresses( address[] calldata _nonCirculatingAddresses ) external returns ( bool ) {
        require( msg.sender == owner, "Sender is not owner" );
        nonCirculatingGaasAddresses = _nonCirculatingAddresses;

        return true;
    }

    function transferOwnership( address _owner ) external returns ( bool ) {
        require( msg.sender == owner, "Sender is not owner" );

        owner = _owner;

        return true;
    }
}