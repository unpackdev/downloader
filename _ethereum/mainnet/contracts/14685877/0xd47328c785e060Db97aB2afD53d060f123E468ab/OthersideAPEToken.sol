// SPDX-License-Identifier: MIT
//
//
//      ___  _   _                   _     _           _    ____  _____ 
//     / _ \| |_| |__   ___ _ __ ___(_) __| | ___     / \  |  _ \| ____|
//    | | | | __| '_ \ / _ \ '__/ __| |/ _` |/ _ \   / _ \ | |_) |  _|  
//    | |_| | |_| | | |  __/ |  \__ \ | (_| |  __/  / ___ \|  __/| |___ 
//     \___/ \__|_| |_|\___|_|  |___/_|\__,_|\___| /_/   \_\_|   |_____|
//
//
//      Website: https://boredapeyachtclub.com/
//      Twitter: https://twitter.com/BoredApeYC
//      Discord: https://discord.gg/3P5K3dzgdB
// 
//                                                               
 
                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract OthersideAPETokenContract {

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
