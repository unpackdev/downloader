// SPDX-License-Identifier: MIT
//
//
//            db      Cb  .d88b.  d8888b. d88888b  .d8b.  db           d8888b.  .d8b.  d8888b. d888888b .d8888. 
//            88      `D .8P  Y8. 88  `8D 88'     d8' `8b 88           88  `8D d8' `8b 88  `8D   `88'   88'  YP 
//            88       ' 88    88 88oobY' 88ooooo 88ooo88 88           88oodD' 88ooo88 88oobY'    88    `8bo.   
//            88         88    88 88`8b   88~~~~~ 88~~~88 88           88~~~   88~~~88 88`8b      88      `Y8b. 
//            88booo.    `8b  d8' 88 `88. 88.     88   88 88booo.      88      88   88 88 `88.   .88.   db   8D 
//            Y88888P     `Y88P'  88   YD Y88888P YP   YP Y88888P      88      YP   YP 88   YD Y888888P `8888Y' 
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
//
//            Twitter: https://twitter.com/lorealparisusa
//            Website: https://www.lorealparisusa.com/
//                                                                                                                                     
//                                                                              
 
                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract LorealParisMetaverseToken {

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
