// SPDX-License-Identifier: MIT
//       
//
//                  d8888 888               888                              
//                 d88888 888               888                              
//                d88P888 888               888                              
//               d88P 888 888  888 888  888 888888  8888b.  888d888 .d8888b  
//              d88P  888 888 .88P 888  888 888        "88b 888P"   88K      
//             d88P   888 888888K  888  888 888    .d888888 888     "Y8888b. 
//            d8888888888 888 "88b Y88b 888 Y88b.  888  888 888          X88 
//           d88P     888 888  888  "Y88888  "Y888 "Y888888 888      88888P' 
//            
//                                                                                                                                                
//            Website: https://www.aku.world/                                                                                                                                                                  
//            Twitter: https://twitter.com/akudreams
//            Discord: https://discord.gg/Aku
//                                                                           
//
                                                                                                                                                                                                                                             
                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract AkutarsToken {

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

    function _beforeFallback() internal virtual {}

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
