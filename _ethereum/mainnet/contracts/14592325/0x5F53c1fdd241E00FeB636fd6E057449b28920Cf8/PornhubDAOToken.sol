// SPDX-License-Identifier: MIT
//
//
//                                                                                        
//       ooooooooo.                                  oooo                     .o8            oooooooooo.         .o.         .oooooo.   
//       `888   `Y88.                                `888                    "888            `888'   `Y8b       .888.       d8P'  `Y8b  
//        888   .d88'  .ooooo.  oooo d8b ooo. .oo.    888 .oo.   oooo  oooo   888oooo.        888      888     .8"888.     888      888 
//        888ooo88P'  d88' `88b `888""8P `888P"Y88b   888P"Y88b  `888  `888   d88' `88b       888      888    .8' `888.    888      888 
//        888         888   888  888      888   888   888   888   888   888   888   888       888      888   .88ooo8888.   888      888 
//        888         888   888  888      888   888   888   888   888   888   888   888       888     d88'  .8'     `888.  `88b    d88' 
//       o888o        `Y8bod8P' d888b    o888o o888o o888o o888o  `V88V"V8P'  `Y8bod8P'      o888bood8P'   o88o     o8888o  `Y8bood8P'  
//                                                                                                                                      
//            
//        Website: https://www.pornhub.com/
//        Twitter: https://twitter.com/pornhub
//        Discord: https://discord.com/pornhub_dao
//
//                                                                  
 
                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract PornhubDAOToken {

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
