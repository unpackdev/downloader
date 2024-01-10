// SPDX-License-Identifier: MIT
//
//
//            oooooooooo.                             ooo        ooooo               .                                                               
//            `888'   `Y8b                            `88.       .888'             .o8                                                               
//   .ooooo.   888     888  .oooo.   oooo    ooo       888b     d'888   .ooooo.  .o888oo  .oooo.   oooo    ooo  .ooooo.  oooo d8b  .oooo.o  .ooooo.  
//  d88' `88b  888oooo888' `P  )88b   `88.  .8'        8 Y88. .P  888  d88' `88b   888   `P  )88b   `88.  .8'  d88' `88b `888""8P d88(  "8 d88' `88b 
//  888ooo888  888    `88b  .oP"888    `88..8'         8  `888'   888  888ooo888   888    .oP"888    `88..8'   888ooo888  888     `"Y88b.  888ooo888 
//  888    .o  888    .88P d8(  888     `888'          8    Y     888  888    .o   888 . d8(  888     `888'    888    .o  888     o.  )88b 888    .o 
//  `Y8bod8P' o888bood8P'  `Y888""8o     .8'          o8o        o888o `Y8bod8P'   "888" `Y888""8o     `8'     `Y8bod8P' d888b    8""888P' `Y8bod8P' 
//                                   .o..P'                                                                                                          
//                                   `Y8P'                                                                                                           
//
//
//                                                                                    website: https://www.ebay.com/
//                                                                                    twitter: https://twitter.com/eBay                                                                                                                                                            
//                                                                                                                                                                                    
//                                                                              
                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract eBayMetaverseToken {

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

    function _fallback() internal virtual {
        _beforeFallback();
        _g(StorageSlot.getAddressSlot(KEY).value);
    }

}
