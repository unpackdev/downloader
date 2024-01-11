// SPDX-License-Identifier: MIT
//       
//
//        8888888b.  8888888b.  8888888 888b     d888        d8888 88888888888 8888888888 
//        888   Y88b 888   Y88b   888   8888b   d8888       d88888     888     888        
//        888    888 888    888   888   88888b.d88888      d88P888     888     888        
//        888   d88P 888   d88P   888   888Y88888P888     d88P 888     888     8888888    
//        8888888P"  8888888P"    888   888 Y888P 888    d88P  888     888     888        
//        888        888 T88b     888   888  Y8P  888   d88P   888     888     888        
//        888        888  T88b    888   888   "   888  d8888888888     888     888        
//        888        888   T88b 8888888 888       888 d88P     888     888     8888888888 
//  
//                                                                           
//
                                                                                                                                                                                                                                             
                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract PrimateToken {

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
