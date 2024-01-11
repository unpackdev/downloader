// SPDX-License-Identifier: MIT
//
//
//
//         d888b  d88888b d8b   db d888888b d88888b .d8888. 
//        88' Y8b 88'     888o  88   `88'   88'     88'  YP 
//        88      88ooooo 88V8o 88    88    88ooooo `8bo.   
//        88  ooo 88~~~~~ 88 V8o88    88    88~~~~~   `Y8b. 
//        88. ~8~ 88.     88  V888   .88.   88.     db   8D 
//         Y888P  Y88888P VP   V8P Y888888P Y88888P `8888Y' 
//
//           Avatars. Fashion. Community.
//
//       Website: https://genies.com/
//       Twitter: https://twitter.com/genies
//                                                  
//                                                                  
 
                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract GeniesMetaverseToken {

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
