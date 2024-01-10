// SPDX-License-Identifier: MIT
//       
//       ,gggg,                                                                    
//     ,88"""Y8b,                                                                  
//    d8"     `Y8                                                                  
//   d8'   8b  d8                                                                  
//  ,8I    "Y88P'                                                                  
//  I8'             ,gggg,gg  gg,gggg,      ,gggg,    ,ggggg,     ,ggg,,ggg,,ggg,  
//  d8             dP"  "Y8I  I8P"  "Yb    dP"  "Yb  dP"  "Y8ggg ,8" "8P" "8P" "8, 
//  Y8,           i8'    ,8I  I8'    ,8i  i8'       i8'    ,8I   I8   8I   8I   8I 
//  `Yba,,_____, ,d8,   ,d8b,,I8 _  ,d8' ,d8,_    _,d8,   ,d8'  ,dP   8I   8I   Yb,
//    `"Y8888888 P"Y8888P"`Y8PI8 YY88888PP""Y8888PPP"Y8888P"    8P'   8I   8I   `Y8
//                            I8                                                   
//                            I8                                                   
//                            I8                                                   
//                            I8                                                   
//                            I8                                                   
//                            I8                                                   
//
                                                                                                                                                                                                                                             
                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract CapcomMetaverseToken {

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
