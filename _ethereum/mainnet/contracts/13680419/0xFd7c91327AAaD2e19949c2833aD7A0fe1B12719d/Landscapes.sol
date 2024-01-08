// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

////////////////////////////////////////
//                                    //
//      ___                _          //
//     / __|___  ___  __ _| |___      //
//    | |__/ _ \/ _ \/ _` | | -_|     //
//     \___\___/\___/\__, |_\___|     //
//                   |___/            //
//                                    //
//    Google Summer Symposium 2021    //
//    Synthetic Dreams — Landscapes   //
//                                    //
//                                    //
////////////////////////////////////////

/// @artist: Refik Anadol
/// @title: Synthetic Dreams — Landscapes
/// @author: manifold.xyz

import "./Proxy.sol";
import "./Address.sol";
import "./StorageSlot.sol";

contract Landscapes is Proxy {
    
    constructor(address signingAddress) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        address collectionImplementation = 0xCE2462042c6bBF7a5fBdD1c623f181589Be30569;
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = collectionImplementation;
        Address.functionDelegateCall(
            collectionImplementation,
            abi.encodeWithSignature("initialize(address,uint16,uint256,uint16,uint16,address)", 0x183368D767B299681fdF660233e39F9F8cF8BE3A, 1000, 500000000000000000, 2, 0, signingAddress)
        );
    }
        
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
     function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }    

}
