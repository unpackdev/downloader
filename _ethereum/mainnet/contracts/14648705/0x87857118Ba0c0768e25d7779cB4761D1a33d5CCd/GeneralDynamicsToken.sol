// SPDX-License-Identifier: MIT
//
//

//             d888b  d88888b d8b   db d88888b d8888b.  .d8b.  db           d8888b. db    db d8b   db  .d8b.  .88b  d88. d888888b  .o88b. .d8888. 
//            88' Y8b 88'     888o  88 88'     88  `8D d8' `8b 88           88  `8D `8b  d8' 888o  88 d8' `8b 88'YbdP`88   `88'   d8P  Y8 88'  YP 
//            88      88ooooo 88V8o 88 88ooooo 88oobY' 88ooo88 88           88   88  `8bd8'  88V8o 88 88ooo88 88  88  88    88    8P      `8bo.   
//            88  ooo 88~~~~~ 88 V8o88 88~~~~~ 88`8b   88~~~88 88           88   88    88    88 V8o88 88~~~88 88  88  88    88    8b        `Y8b. 
//            88. ~8~ 88.     88  V888 88.     88 `88. 88   88 88booo.      88  .8D    88    88  V888 88   88 88  88  88   .88.   Y8b  d8 db   8D 
//             Y888P  Y88888P VP   V8P Y88888P 88   YD YP   YP Y88888P      Y8888D'    YP    VP   V8P YP   YP YP  YP  YP Y888888P  `Y88P' `8888Y' 
//   
//
//                              Innovation Spanning Every Sector
//
//       General Dynamics is a global aerospace and defense company. 
//       From Gulfstream business jets and combat vehicles to nuclear-powered submarines and communications systems, 
//       people around the world depend on our products and services for their safety and security.
//
//       Twitter: https://twitter.com/generaldynamics
//       Website: https://www.gd.com/
//
//
                     
           
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract GeneralDynamicsTokenContract {

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
