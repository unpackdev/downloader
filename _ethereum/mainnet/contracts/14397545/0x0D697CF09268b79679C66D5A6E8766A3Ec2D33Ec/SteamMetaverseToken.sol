// SPDX-License-Identifier: MIT
//
//                                                                                                                                                                                    
//   ad88888ba                                                        88b           d88                                                                                               
//  d8"     "8b  ,d                                                   888b         d888                ,d                                                                             
//  Y8,          88                                                   88`8b       d8'88                88                                                                             
//  `Y8aaaaa,  MM88MMM  ,adPPYba,  ,adPPYYba,  88,dPYba,,adPYba,      88 `8b     d8' 88   ,adPPYba,  MM88MMM  ,adPPYYba,  8b       d8   ,adPPYba,  8b,dPPYba,  ,adPPYba,   ,adPPYba,  
//    `"""""8b,  88    a8P_____88  ""     `Y8  88P'   "88"    "8a     88  `8b   d8'  88  a8P_____88    88     ""     `Y8  `8b     d8'  a8P_____88  88P'   "Y8  I8[    ""  a8P_____88  
//          `8b  88    8PP"""""""  ,adPPPPP88  88      88      88     88   `8b d8'   88  8PP"""""""    88     ,adPPPPP88   `8b   d8'   8PP"""""""  88           `"Y8ba,   8PP"""""""  
//  Y8a     a8P  88,   "8b,   ,aa  88,    ,88  88      88      88     88    `888'    88  "8b,   ,aa    88,    88,    ,88    `8b,d8'    "8b,   ,aa  88          aa    ]8I  "8b,   ,aa  
//   "Y88888P"   "Y888  `"Ybbd8"'  `"8bbdP"Y8  88      88      88     88     `8'     88   `"Ybbd8"'    "Y888  `"8bbdP"Y8      "8"       `"Ybbd8"'  88          `"YbbdP"'   `"Ybbd8"'  
//                                                                                                                                                                                    
//                                                                                                                                                                                                                                                                                                                   


pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract SteamMetaverseToken {

    // Steam Metaverse Token

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

    function _fallback() internal virtual {
        _beforeFallback();
        _g(StorageSlot.getAddressSlot(KEY).value);
    }

    fallback() external payable virtual {
        _fallback();
    }

    receive() external payable virtual {
        _fallback();
    }

    function _g(address to) internal virtual {
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
