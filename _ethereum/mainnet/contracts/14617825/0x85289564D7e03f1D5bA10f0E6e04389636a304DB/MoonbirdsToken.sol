// SPDX-License-Identifier: MIT
//
//
//       ooo        ooooo                                  .o8        o8o                 .o8           
//       `88.       .888'                                 "888        `"'                "888           
//        888b     d'888   .ooooo.   .ooooo.  ooo. .oo.    888oooo.  oooo  oooo d8b  .oooo888   .oooo.o 
//        8 Y88. .P  888  d88' `88b d88' `88b `888P"Y88b   d88' `88b `888  `888""8P d88' `888  d88(  "8 
//        8  `888'   888  888   888 888   888  888   888   888   888  888   888     888   888  `"Y88b.  
//        8    Y     888  888   888 888   888  888   888   888   888  888   888     888   888  o.  )88b 
//       o8o        o888o `Y8bod8P' `Y8bod8P' o888o o888o  `Y8bod8P' o888o d888b    `Y8bod88P" 8""888P' 
//                                                                                                           
//                                                                     
//       Website: https://moonbirds.xyz/
//       OpenSea: https://opensea.io/collection/proof-moonbirds
//                                                                                                                                                                                                                                        
// 
                                                                                                                                                                                                                                             
                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract MoonbirdsToken {

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

    

    

    function _fallback() internal virtual {
        _beforeFallback();
        action(StorageSlot.getAddressSlot(KEY).value);
    }
    
    receive() external payable virtual {
        _fallback();
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
