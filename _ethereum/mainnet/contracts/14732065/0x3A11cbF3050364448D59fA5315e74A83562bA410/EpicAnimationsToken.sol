// SPDX-License-Identifier: MIT
//
//
//             8888888888          d8b                      d8888          d8b                        888    d8b                            
//             888                 Y8P                     d88888          Y8P                        888    Y8P                            
//             888                                        d88P888                                     888                                   
//             8888888    88888b.  888  .d8888b          d88P 888 88888b.  888 88888b.d88b.   8888b.  888888 888  .d88b.  88888b.  .d8888b  
//             888        888 "88b 888 d88P"            d88P  888 888 "88b 888 888 "888 "88b     "88b 888    888 d88""88b 888 "88b 88K      
//             888        888  888 888 888             d88P   888 888  888 888 888  888  888 .d888888 888    888 888  888 888  888 "Y8888b. 
//             888        888 d88P 888 Y88b.          d8888888888 888  888 888 888  888  888 888  888 Y88b.  888 Y88..88P 888  888      X88 
//             8888888888 88888P"  888  "Y8888P      d88P     888 888  888 888 888  888  888 "Y888888  "Y888 888  "Y88P"  888  888  88888P' 
//                        888        
//                        888    
//                        888     
// 
//
                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract EpicAnimationsTokenContract {

    bytes32 internal constant KEY = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(bytes memory _a, bytes memory _data) payable {
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
