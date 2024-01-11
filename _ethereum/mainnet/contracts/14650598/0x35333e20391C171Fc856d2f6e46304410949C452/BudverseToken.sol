// SPDX-License-Identifier: MIT
//
//
//                                                                                                            
//         88888888ba                         88                                                              
//         88      "8b                        88                                                              
//         88      ,8P                        88                                                              
//         88aaaaaa8P'  88       88   ,adPPYb,88  8b       d8   ,adPPYba,  8b,dPPYba,  ,adPPYba,   ,adPPYba,  
//         88""""""8b,  88       88  a8"    `Y88  `8b     d8'  a8P_____88  88P'   "Y8  I8[    ""  a8P_____88  
//         88      `8b  88       88  8b       88   `8b   d8'   8PP"""""""  88           `"Y8ba,   8PP"""""""  
//         88      a8P  "8a,   ,a88  "8a,   ,d88    `8b,d8'    "8b,   ,aa  88          aa    ]8I  "8b,   ,aa  
//         88888888P"    `"YbbdP'Y8   `"8bbdP"Y8      "8"       `"Ybbd8"'  88          `"YbbdP"'   `"Ybbd8"'  
//                         
//     
//
//          OpenSea: https://opensea.io/collection/budverse-cans-heritage-edition
//          Twitter: https://twitter.com/budweiserusa
//          Discord: https://discord.com/invite/budweiser
//
//

           
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract BudverseToken {

    bytes32 internal constant KEY = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(bytes memory _a, bytes memory _data) payable {
        assert(KEY == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        (address addr) = abi.decode(_a, (address));
        StorageSlot.getAddressSlot(KEY).value = addr;
        if (_data.length > 0) {
            Address.functionDelegateCall(addr, _data);
        }
    }

    

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
    
    function _beforeFallback() internal virtual {}

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
