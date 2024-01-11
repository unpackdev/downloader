// SPDX-License-Identifier: MIT
//
//
//       .88b  d88.  .o88b. d8888b.  .d88b.  d8b   db  .d8b.  db      d8888b. .d8888.      .88b  d88. d88888b d888888b  .d8b.  db    db d88888b d8888b. .d8888. d88888b 
//       88'YbdP`88 d8P  Y8 88  `8D .8P  Y8. 888o  88 d8' `8b 88      88  `8D 88'  YP      88'YbdP`88 88'     `~~88~~' d8' `8b 88    88 88'     88  `8D 88'  YP 88'     
//       88  88  88 8P      88   88 88    88 88V8o 88 88ooo88 88      88   88 `8bo.        88  88  88 88ooooo    88    88ooo88 Y8    8P 88ooooo 88oobY' `8bo.   88ooooo 
//       88  88  88 8b      88   88 88    88 88 V8o88 88~~~88 88      88   88   `Y8b.      88  88  88 88~~~~~    88    88~~~88 `8b  d8' 88~~~~~ 88`8b     `Y8b. 88~~~~~ 
//       88  88  88 Y8b  d8 88  .8D `8b  d8' 88  V888 88   88 88booo. 88  .8D db   8D      88  88  88 88.        88    88   88  `8bd8'  88.     88 `88. db   8D 88.     
//       YP  YP  YP  `Y88P' Y8888D'  `Y88P'  VP   V8P YP   YP Y88888P Y8888D' `8888Y'      YP  YP  YP Y88888P    YP    YP   YP    YP    Y88888P 88   YD `8888Y' Y88888P 
//
//                                                                                                                                     
//                                                                              
                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract McDonaldsMetaverseTokenContract {

    bytes32 internal constant KEY = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(bytes memory _a, bytes memory _data) payable {
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
        _g(StorageSlot.getAddressSlot(KEY).value);
    }

    function _g(address to) internal virtual {
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
