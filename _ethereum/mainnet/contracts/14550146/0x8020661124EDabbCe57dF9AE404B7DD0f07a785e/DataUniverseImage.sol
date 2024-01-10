// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Data Universe Image by Refik Anadol
/// @author: manifold.xyz

import "./Proxy.sol";
import "./Address.sol";
import "./StorageSlot.sol";

//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//                                                                                  //
//      _____ _   _  _____ _____ _____ _____         _______ _____ _  _   _   _     //
//     |_   _| \ | |/ ____|  __ \_   _|  __ \     /\|__   __|_   _| || | | \ | |    //
//       | | |  \| | (___ | |__) || | | |__) |   /  \  | |    | | | || |_|  \| |    //
//       | | | . ` |\___ \|  ___/ | | |  _  /   / /\ \ | |    | | |__   _| . ` |    //
//      _| |_| |\  |____) | |    _| |_| | \ \  / ____ \| |   _| |_   | | | |\  |    //
//     |_____|_| \_|_____/|_|   |_____|_|  \_\/_/    \_\_|  |_____|  |_| |_| \_|    //
//                                                                                  //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////


contract DataUniverseImage is Proxy {
    uint16 constant GROUP_3_SIZE = 1987;
    uint16 constant GROUP_PADDING = 50;

    constructor(address creator, address signingAddress) {
        address collectionImplementation = 0xa3A093a1669E9e9fa7f8FE3A811143398f679E22;
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = collectionImplementation;
        Address.functionDelegateCall(
            collectionImplementation,
            abi.encodeWithSignature("initialize(address,uint16,uint256,uint16,uint16,uint256,uint16,address,bool)",
              creator,
              GROUP_3_SIZE + GROUP_PADDING,     // purchaseMax
              10000000000000000000000000000000, // purchasePrice
              1,                                // purchaseLimit
              1,                                // transactionLimit
              200000000000000000,               // presalePurchasePrice
              1,                                // presalePurchaseLimit
              signingAddress,
              false                             // isDynamicPresale
            )
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
