// SPDX-License-Identifier: AGPL-3.0-or-later\
pragma solidity 0.7.5;

import "./IERC20.sol";

import "./SafeMath.sol";

contract AxeCirculatingSupply {
    using SafeMath for uint;

    bool public isInitialized;

    address public AXE;
    address public owner;
    address[] public nonCirculatingAXEAddresses;

    constructor( address _owner ) {
        owner = _owner;
    }

    function initialize( address _axe ) external returns ( bool ) {
        require( msg.sender == owner, "caller is not owner" );
        require( isInitialized == false );

        AXE = _axe;

        isInitialized = true;

        return true;
    }

    function AXECirculatingSupply() external view returns ( uint ) {
        uint _totalSupply = IERC20( AXE ).totalSupply();

        uint _circulatingSupply = _totalSupply.sub( getNonCirculatingAXE() );

        return _circulatingSupply;
    }

    function getNonCirculatingAXE() public view returns ( uint ) {
        uint _nonCirculatingAXE;

        for( uint i=0; i < nonCirculatingAXEAddresses.length; i = i.add( 1 ) ) {
            _nonCirculatingAXE = _nonCirculatingAXE.add( IERC20( AXE ).balanceOf( nonCirculatingAXEAddresses[i] ) );
        }

        return _nonCirculatingAXE;
    }

    function setNonCirculatingAXEAddresses( address[] calldata _nonCirculatingAddresses ) external returns ( bool ) {
        require( msg.sender == owner, "Sender is not owner" );
        nonCirculatingAXEAddresses = _nonCirculatingAddresses;

        return true;
    }

    function transferOwnership( address _owner ) external returns ( bool ) {
        require( msg.sender == owner, "Sender is not owner" );

        owner = _owner;

        return true;
    }
}
