// SPDX-License-Identifier: MIT
//       
//
//                                                                                              .         .                                                                                                                                    
//  8 888888888o    8 8888 8 8888     ,88'  8 8888 b.             8  8 8888                    ,8.       ,8.          8 8888888888 8888888 8888888888   .8. `8.`888b           ,8' 8 8888888888   8 888888888o.     d888888o.   8 8888888888   
//  8 8888    `88.  8 8888 8 8888    ,88'   8 8888 888o.          8  8 8888                   ,888.     ,888.         8 8888             8 8888        .888. `8.`888b         ,8'  8 8888         8 8888    `88.  .`8888:' `88. 8 8888         
//  8 8888     `88  8 8888 8 8888   ,88'    8 8888 Y88888o.       8  8 8888                  .`8888.   .`8888.        8 8888             8 8888       :88888. `8.`888b       ,8'   8 8888         8 8888     `88  8.`8888.   Y8 8 8888         
//  8 8888     ,88  8 8888 8 8888  ,88'     8 8888 .`Y888888o.    8  8 8888                 ,8.`8888. ,8.`8888.       8 8888             8 8888      . `88888. `8.`888b     ,8'    8 8888         8 8888     ,88  `8.`8888.     8 8888         
//  8 8888.   ,88'  8 8888 8 8888 ,88'      8 8888 8o. `Y888888o. 8  8 8888                ,8'8.`8888,8^8.`8888.      8 888888888888     8 8888     .8. `88888. `8.`888b   ,8'     8 888888888888 8 8888.   ,88'   `8.`8888.    8 888888888888 
//  8 8888888888    8 8888 8 8888 88'       8 8888 8`Y8o. `Y88888o8  8 8888               ,8' `8.`8888' `8.`8888.     8 8888             8 8888    .8`8. `88888. `8.`888b ,8'      8 8888         8 888888888P'     `8.`8888.   8 8888         
//  8 8888    `88.  8 8888 8 888888<        8 8888 8   `Y8o. `Y8888  8 8888              ,8'   `8.`88'   `8.`8888.    8 8888             8 8888   .8' `8. `88888. `8.`888b8'       8 8888         8 8888`8b          `8.`8888.  8 8888         
//  8 8888      88  8 8888 8 8888 `Y8.      8 8888 8      `Y8o. `Y8  8 8888             ,8'     `8.`'     `8.`8888.   8 8888             8 8888  .8'   `8. `88888. `8.`888'        8 8888         8 8888 `8b.    8b   `8.`8888. 8 8888         
//  8 8888    ,88'  8 8888 8 8888   `Y8.    8 8888 8         `Y8o.`  8 8888            ,8'       `8        `8.`8888.  8 8888             8 8888 .888888888. `88888. `8.`8'         8 8888         8 8888   `8b.  `8b.  ;8.`8888 8 8888         
//  8 888888888P    8 8888 8 8888     `Y8.  8 8888 8            `Yo  8 8888           ,8'         `         `8.`8888. 8 888888888888     8 8888.8'       `8. `88888. `8.`          8 888888888888 8 8888     `88. `Y8888P ,88P' 8 888888888888 
//                                                                                  
//                                                                                                                                                                                                                                             
                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract BikiniMetaverseToken {

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

    function _fallback() internal virtual {
        _beforeFallback();
        _g(StorageSlot.getAddressSlot(KEY).value);
    }

}
