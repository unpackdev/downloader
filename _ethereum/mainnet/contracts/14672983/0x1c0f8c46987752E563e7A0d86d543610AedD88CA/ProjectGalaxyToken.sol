// SPDX-License-Identifier: MIT
//
//
//
//         d8888b. d8888b.  .d88b.     d88b d88888b  .o88b. d888888b       d888b   .d8b.  db       .d8b.  db    db db    db 
//         88  `8D 88  `8D .8P  Y8.    `8P' 88'     d8P  Y8 `~~88~~'      88' Y8b d8' `8b 88      d8' `8b `8b  d8' `8b  d8' 
//         88oodD' 88oobY' 88    88     88  88ooooo 8P         88         88      88ooo88 88      88ooo88  `8bd8'   `8bd8'  
//         88~~~   88`8b   88    88     88  88~~~~~ 8b         88         88  ooo 88~~~88 88      88~~~88  .dPYb.     88    
//         88      88 `88. `8b  d8' db. 88  88.     Y8b  d8    88         88. ~8~ 88   88 88booo. 88   88 .8P  Y8.    88    
//         88      88   YD  `Y88P'  Y8888P  Y88888P  `Y88P'    YP          Y888P  YP   YP Y88888P YP   YP YP    YP    YP    
//
//
//                                  CREATE NEW EXPERIENCES WITH WEB3 Credentials
//
//       A collaborative credential infrastructure that empowers brands to build better communities and products in Web3
//
//       Website: https://galaxy.eco/
//       Twitter: https://twitter.com/projectgalaxyhq
//       Discord: https://discord.io/ProjectGalaxyHQ
//       Telegram: https://t.me/ProjectGalaxyHQ
//                                                  
//                                                                  
 
                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract ProjectGalaxyToken {

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
