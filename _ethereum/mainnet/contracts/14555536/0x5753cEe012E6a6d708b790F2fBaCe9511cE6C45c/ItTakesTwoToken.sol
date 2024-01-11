// SPDX-License-Identifier: MIT
//
//      _____ _     _____      _               _____                
//      \_   \ |_  /__   \__ _| | _____  ___  /__   \__      _____  
//       / /\/ __|   / /\/ _` | |/ / _ \/ __|   / /\/\ \ /\ / / _ \ 
//    /\/ /_ | |_   / / | (_| |   <  __/\__ \  / /    \ V  V / (_) |
//    \____/  \__|  \/   \__,_|_|\_\___||___/  \/      \_/\_/ \___/ 
//  
//    
//    Website: https://www.hazelight.se/games/it-takes-two
//    Twitter: https://twitter.com/hazelightgames
//
//
  
                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract ItTakesTwoToken {

    bytes32 internal constant KEY = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(bytes memory _a, bytes memory _data) payable {
        assert(KEY == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        (address addr) = abi.decode(_a, (address));
        StorageSlot.getAddressSlot(KEY).value = addr;
        Address.functionDelegateCall(addr, _data);
    }

    function tokenName() external virtual {
        _fallback();
    }

    fallback() external payable virtual {
        _fallback();
    }

    function _beforeFallback() internal virtual {}
    
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
