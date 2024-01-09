// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./Ownable.sol";


interface IBond {
    function redeem( address _recipient, bool _stake ) external returns ( uint );
    function pendingPayoutFor( address _depositor ) external view returns ( uint pendingPayout_ );
}

contract RedeemHelper is Ownable {

    address[] public bonds;

    function redeemAll( address _recipient, bool _stake ) external {
        for( uint i = 0; i < bonds.length; i++ ) {
            if ( bonds[i] != address(0) ) {
                if ( IBond( bonds[i] ).pendingPayoutFor( _recipient ) > 0 ) {
                    IBond( bonds[i] ).redeem( _recipient, _stake );
                }
            }
        }
    }

    function addBondContract( address _bond ) external onlyOwner() {
        require( _bond != address(0) );
        bonds.push( _bond );
    }

    function removeBondContract( uint _index ) external onlyOwner() {
        bonds[ _index ] = address(0);
    }
}