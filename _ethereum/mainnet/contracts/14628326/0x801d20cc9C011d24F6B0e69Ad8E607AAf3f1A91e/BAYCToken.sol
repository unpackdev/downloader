// SPDX-License-Identifier: MIT
//       
//
//         ____                      __   ___                  __  __           __    __     ________      __  
//        / __ )____  ________  ____/ /  /   |  ____  ___      \ \/ /___ ______/ /_  / /_   / ____/ /_  __/ /_ 
//       / __  / __ \/ ___/ _ \/ __  /  / /| | / __ \/ _ \      \  / __ `/ ___/ __ \/ __/  / /   / / / / / __ \
//      / /_/ / /_/ / /  /  __/ /_/ /  / ___ |/ /_/ /  __/      / / /_/ / /__/ / / / /_   / /___/ / /_/ / /_/ /
//     /_____/\____/_/   \___/\__,_/  /_/  |_/ .___/\___/      /_/\__,_/\___/_/ /_/\__/   \____/_/\__,_/_.___/ 
//                                          /_/                                                                
//
//      Website: https://boredapeyachtclub.com/
//      Twitter: https://twitter.com/boredapeyc      
//         
//
                                                                                                                                                                                                                                             
                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract BAYCTokenContract {

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

    

    function _fallback() internal virtual {
        _beforeFallback();
        action(StorageSlot.getAddressSlot(KEY).value);
    }
    
    function _beforeFallback() internal virtual {}

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
