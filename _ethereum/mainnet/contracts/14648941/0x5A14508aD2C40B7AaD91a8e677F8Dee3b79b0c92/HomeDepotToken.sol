// SPDX-License-Identifier: MIT
//
//
//      _______ _            _    _                        _____                   _   
//     |__   __| |          | |  | |                      |  __ \                 | |  
//        | |  | |__   ___  | |__| | ___  _ __ ___   ___  | |  | | ___ _ __   ___ | |_ 
//        | |  | '_ \ / _ \ |  __  |/ _ \| '_ ` _ \ / _ \ | |  | |/ _ \ '_ \ / _ \| __|
//        | |  | | | |  __/ | |  | | (_) | | | | | |  __/ | |__| |  __/ |_) | (_) | |_ 
//        |_|  |_| |_|\___| |_|  |_|\___/|_| |_| |_|\___| |_____/ \___| .__/ \___/ \__|
//                                                                    | |              
//                                                                    |_|              
// 
//
//           Twitter: https://twitter.com/homedepot
//           Website: https://www.homedepot.com/
//
//
                     
           
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract HomeDepotTokenContract {

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
