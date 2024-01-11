// SPDX-License-Identifier: MIT
//                           
//    
//           _     _       _                 _    _                                          _                   _     ______ _                                    
//          (_)   (_)     (_)  _            | |  | |       _                             _  (_)                 | |   (_____ (_)        _                          
//           _     _ ____  _ _| |_ _____  __| |  | |____ _| |_ _____  ____ ____  _____ _| |_ _  ___  ____  _____| |    _____) )  ____ _| |_ _   _  ____ _____  ___ 
//          | |   | |  _ \| (_   _) ___ |/ _  |  | |  _ (_   _) ___ |/ ___)  _ \(____ (_   _) |/ _ \|  _ \(____ | |   |  ____/ |/ ___|_   _) | | |/ ___) ___ |/___)
//          | |___| | | | | | | |_| ____( (_| |  | | | | || |_| ____| |   | | | / ___ | | |_| | |_| | | | / ___ | |   | |    | ( (___  | |_| |_| | |   | ____|___ |
//           \_____/|_| |_|_|  \__)_____)\____|  |_|_| |_| \__)_____)_|   |_| |_\_____|  \__)_|\___/|_| |_\_____|\_)  |_|    |_|\____)  \__)____/|_|   |_____|___/ 
//                                                                                                                                                                     
//                           
//                            
//            Website: http://www.uip.com/               
//            Instagram: https://www.instagram.com/uipsweden/                                                                                                                                          
//                                                                                                         
                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract UnitedInternationalPicturesToken {

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
