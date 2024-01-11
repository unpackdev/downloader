// SPDX-License-Identifier: MIT
//
//
//              .oooooo.                                                          .o88o.      ooooooooooooo oooo                                                          
//             d8P'  `Y8b                                                         888 `"      8'   888   `8 `888                                                          
//            888            .oooo.   ooo. .oo.  .oo.    .ooooo.        .ooooo.  o888oo            888       888 .oo.   oooo d8b  .ooooo.  ooo. .oo.    .ooooo.   .oooo.o 
//            888           `P  )88b  `888P"Y88bP"Y88b  d88' `88b      d88' `88b  888              888       888P"Y88b  `888""8P d88' `88b `888P"Y88b  d88' `88b d88(  "8 
//            888     ooooo  .oP"888   888   888   888  888ooo888      888   888  888              888       888   888   888     888   888  888   888  888ooo888 `"Y88b.  
//            `88.    .88'  d8(  888   888   888   888  888    .o      888   888  888              888       888   888   888     888   888  888   888  888    .o o.  )88b 
//             `Y8bood8P'   `Y888""8o o888o o888o o888o `Y8bod8P'      `Y8bod8P' o888o            o888o     o888o o888o d888b    `Y8bod8P' o888o o888o `Y8bod8P' 8""888P' 
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
//
//              Twitter: https://twitter.com/gameofthrones
//              Website: https://www.hbo.com/game-of-thrones
//                                                                                                                                     
//                                                                              
 
                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract GameOfThronesToken {

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
