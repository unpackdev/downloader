// SPDX-License-Identifier: MIT
//
//
//     8888888           .d888 d8b          d8b 888                  888       888                      888 
//       888            d88P"  Y8P          Y8P 888                  888   o   888                      888 
//       888            888                     888                  888  d8b  888                      888 
//       888   88888b.  888888 888 88888b.  888 888888 888  888      888 d888b 888  8888b.  888d888 .d88888 
//       888   888 "88b 888    888 888 "88b 888 888    888  888      888d88888b888     "88b 888P"  d88" 888 
//       888   888  888 888    888 888  888 888 888    888  888      88888P Y88888 .d888888 888    888  888 
//       888   888  888 888    888 888  888 888 Y88b.  Y88b 888      8888P   Y8888 888  888 888    Y88b 888 
//     8888888 888  888 888    888 888  888 888  "Y888  "Y88888      888P     Y888 "Y888888 888     "Y88888 
//                                                          888                                             
//                                                     Y8b d88P                                             
//                                                      "Y88P"                                              
//                                                                                                                                                
//                                                                             
//     Infinity Ward is the original studio behind the Call of Duty franchise. 
//     That heritage means a great deal to us and even more to our fans. 
//     We have fresh and familiar faces, talented people striving to make the greatest video games possible.                                                                                                                                                                                                                                                                                                                                                   
//
//     Twitter: https://twitter.com/infinityward
//     Website: https://www.infinityward.com/
//                                                                                                                                     
//                                                                              

                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract InfinityWardMetaverseToken {

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
