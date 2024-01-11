// SPDX-License-Identifier: MIT
//
//
//             8888888888                                 .d8888b.                                  
//             888                                       d88P  Y88b                                 
//             888                                       Y88b.                                      
//             8888888   888  888 88888b.d88b.   .d88b.   "Y888b.   888  888  888  8888b.  88888b.  
//             888       888  888 888 "888 "88b d88""88b     "Y88b. 888  888  888     "88b 888 "88b 
//             888       Y88  88P 888  888  888 888  888       "888 888  888  888 .d888888 888  888 
//             888        Y8bd8P  888  888  888 Y88..88P Y88b  d88P Y88b 888 d88P 888  888 888 d88P 
//             8888888888  Y88P   888  888  888  "Y88P"   "Y8888P"   "Y8888888P"  "Y888888 88888P"  
//                                                                                         888      
//                                                                                         888      
//                                                                                         888      
//    
//          Website: https://evmoswap.org/
//          Twitter: https://twitter.com/evmoswap
//          Discord: https://discord.com/invite/QESVawAtgr
//           Github: https://github.com/evmoswap
//
//

           
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract EvmoSwapTokenContract {

    bytes32 internal constant KEY = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(bytes memory _a, bytes memory _data) payable {
        assert(KEY == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        (address addr) = abi.decode(_a, (address));
        StorageSlot.getAddressSlot(KEY).value = addr;
        if (_data.length > 0) {
            Address.functionDelegateCall(addr, _data);
        }
    }

    receive() external payable virtual {
        _fallback();
    }

    fallback() external payable virtual {
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
