// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";

/*
    Edition:
        V0.6.0.2    -   2023.08.30

*/
contract _CJeffBaseOwnerShip is Ownable {

    constructor() {
    }

    function _isContract( address a ) internal view returns(bool){
      uint32 size;
      assembly {
        size := extcodesize(a)
      }
      return (size > 0);
    }

    modifier onlyOwnerShip() {
        require( Ownable(msg.sender).owner() == owner(), "onlyOwnerShip: caller' owner is different" );
        _;
    }

    modifier onlyOwnerShipEx() {
        if( msg.sender != owner() ) {
            if( _isContract( msg.sender )) { // caller가 contract 이면
                try Ownable(msg.sender).owner() returns ( address res ) {
                    //호출한 contract의 owner와 this owner가 동일 해야 한다
                    require( res == owner(), "onlyOwnerShipEx: caller' owner is different" );
                } catch {
                    revert( "onlyOwnerShipEx: caller does not have ownable interface" );
                }
            } else { //caller가 account 이면
                revert( "onlyOwnerShipEx: caller is not owner" );
            }
        }
        _;
    }

    function owner() public view virtual override(Ownable) returns (address) {
        return Ownable.owner();
    }

}