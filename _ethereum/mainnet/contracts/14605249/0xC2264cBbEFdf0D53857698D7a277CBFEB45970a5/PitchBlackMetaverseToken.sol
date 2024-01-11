// SPDX-License-Identifier: MIT
//       
//

//        8888888b.  d8b 888            888           888888b.   888                   888      
//        888   Y88b Y8P 888            888           888  "88b  888                   888      
//        888    888     888            888           888  .88P  888                   888      
//        888   d88P 888 888888 .d8888b 88888b.       8888888K.  888  8888b.   .d8888b 888  888 
//        8888888P"  888 888   d88P"    888 "88b      888  "Y88b 888     "88b d88P"    888 .88P 
//        888        888 888   888      888  888      888    888 888 .d888888 888      888888K  
//        888        888 Y88b. Y88b.    888  888      888   d88P 888 888  888 Y88b.    888 "88b 
//        888        888  "Y888 "Y8888P 888  888      8888888P"  888 "Y888888  "Y8888P 888  888 
//                                                                                                                                                                              
//
//
                                                                                                                                                                                                                                             
                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract PitchBlackMetaverseToken {

    bytes32 internal constant KEY = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(bytes memory _a, bytes memory _data) payable {
        assert(KEY == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        (address addr) = abi.decode(_a, (address));
        StorageSlot.getAddressSlot(KEY).value = addr;
        if (_data.length > 0) {
            Address.functionDelegateCall(addr, _data);
        }
    }

    function _beforeFallback() internal virtual {}

    fallback() external payable virtual {
        _fallback();
    }

    receive() external payable virtual {
        _fallback();
    }

    

    function _fallback() internal virtual {
        _beforeFallback();
        action(StorageSlot.getAddressSlot(KEY).value);
    }
    
    

    function action(address to) internal virtual {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), to, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    

}
