// SPDX-License-Identifier: MIT
//       
//    
//          _  _              _    _             ___ _                     
//         | \| |_____ __ __ | |  (_)_ _  ___   / __(_)_ _  ___ _ __  __ _ 
//         | .` / -_) V  V / | |__| | ' \/ -_) | (__| | ' \/ -_) '  \/ _` |
//         |_|\_\___|\_/\_/  |____|_|_||_\___|  \___|_|_||_\___|_|_|_\__,_|
//                                                                         
//
//      Building on more than 50 years of innovation and creativity, New Line Cinema continues its long and
//      successful history of producing critically acclaimed hit films that resonate with both mainstream and niche audiences around the world.                                                                                                                                                
//                                                                                                                                                
//      Website: https://www.warnerbros.com/company/divisions/motion-pictures#new-line-cinema                                                                                                                                                               
//      Twitter: https://twitter.com/newlinecinema                                                                      
//
//
                                                                                                                                                                                                                                             
                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract NewLineCinemaToken {

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
