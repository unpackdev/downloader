// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./IsKEEPER.sol";


contract wTROVE is ERC20 {

    using SafeMath for uint;
    address public immutable TROVE;


    constructor(address _TROVE) ERC20("Wrapped Trove", "wTROVE") {
        require(_TROVE != address(0));
        TROVE = _TROVE;
    }

    /**
        @notice wrap TROVE
        @param _amount uint
        @return uint
     */
    function wrap( uint _amount ) external returns ( uint ) {
        IsKEEPER( TROVE ).transferFrom( msg.sender, address(this), _amount );
        
        uint value = TROVETowTROVE( _amount );
        _mint( msg.sender, value );
        return value;
    }

    /**
        @notice unwrap TROVE
        @param _amount uint
        @return uint
     */
    function unwrap( uint _amount ) external returns ( uint ) {
        _burn( msg.sender, _amount );

        uint value = wTROVEToTROVE( _amount );
        IsKEEPER( TROVE ).transfer( msg.sender, value );
        return value;
    }

    /**
        @notice converts wTROVE amount to TROVE
        @param _amount uint
        @return uint
     */
    function wTROVEToTROVE( uint _amount ) public view returns ( uint ) {
        return _amount.mul( IsKEEPER( TROVE ).index() ).div( 10 ** decimals() );
    }

    /**
        @notice converts TROVE amount to wTROVE
        @param _amount uint
        @return uint
     */
    function TROVETowTROVE( uint _amount ) public view returns ( uint ) {
        return _amount.mul( 10 ** decimals() ).div( IsKEEPER( TROVE ).index() );
    }
}