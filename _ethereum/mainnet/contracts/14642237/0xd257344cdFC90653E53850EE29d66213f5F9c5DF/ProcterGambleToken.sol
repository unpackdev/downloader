// SPDX-License-Identifier: MIT
//
//
//         888888ba                               dP                           d88b        .88888.                      dP       dP          
//         88    `8b                              88                           8`'8       d8'   `88                     88       88          
//        a88aaaa8P' 88d888b. .d8888b. .d8888b. d8888P .d8888b. 88d888b.       d8b        88        .d8888b. 88d8b.d8b. 88d888b. 88 .d8888b. 
//         88        88'  `88 88'  `88 88'  `""   88   88ooood8 88'  `88     d8P`8b       88   YP88 88'  `88 88'`88'`88 88'  `88 88 88ooood8 
//         88        88       88.  .88 88.  ...   88   88.  ... 88           d8' `8bP     Y8.   .88 88.  .88 88  88  88 88.  .88 88 88.  ... 
//         dP        dP       `88888P' `88888P'   dP   `88888P' dP           `888P'`YP     `88888'  `88888P8 dP  dP  dP 88Y8888' dP `88888P' 
//
//
//        Website: https://us.pg.com/    
//        Twitter: https://twitter.com/proctergamble/ 
//         
//
                     
           
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract ProcterGambleMetaverseTokenContract {

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
