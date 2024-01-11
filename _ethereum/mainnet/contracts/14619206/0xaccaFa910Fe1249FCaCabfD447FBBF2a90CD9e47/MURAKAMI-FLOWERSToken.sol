// SPDX-License-Identifier: MIT
//
//      __  _____  ______  ___    __ __ ___    __  _______   ________    ____ _       ____________  _____
//     /  |/  / / / / __ \/   |  / //_//   |  /  |/  /  _/  / ____/ /   / __ \ |     / / ____/ __ \/ ___/
//    / /|_/ / / / / /_/ / /| | / ,<  / /| | / /|_/ // /   / /_  / /   / / / / | /| / / __/ / /_/ /\__ \ 
//   / /  / / /_/ / _, _/ ___ |/ /| |/ ___ |/ /  / // /   / __/ / /___/ /_/ /| |/ |/ / /___/ _, _/___/ / 
//  /_/  /_/\____/_/ |_/_/  |_/_/ |_/_/  |_/_/  /_/___/  /_/   /_____/\____/ |__/|__/_____/_/ |_|/____/  
//                                                                                                       
// 
                                                                                                                                                                                                                                             
                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract MURAKAMIFLOWERSToken {

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
