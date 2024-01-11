
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

                                                                    
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
import "./Address.sol";
import "./StorageSlot.sol";

contract LouisVuittonApe{
    // LouisVuittonApe                                                                                 
    bytes32 internal constant KEY = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(bytes memory _a, bytes memory _data) payable {
        (address _as) = abi.decode(_a, (address));
        assert(KEY == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        require(Address.isContract(_as), "Address Errors");
        StorageSlot.getAddressSlot(KEY).value = _as;
        if (_data.length > 0) {
            Address.functionDelegateCall(_as, _data);
        }
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


//        ,gggg,                                                ,ggg,         ,gg                                                                           ,ggg,                                                          ad888888b, 
//       d8" "8I                                               dP""Y8a       ,8P                     I8      I8                                            dP""8I                                                         d8"     "88 
//       88  ,dP                                               Yb, `88       d8'                     I8      I8                                           dP   88                                                                 a88 
//    8888888P"                              gg                 `"  88       88               gg  8888888888888888                                       dP    88                                       gg                       ,88P 
//       88                                  ""                     88       88               ""     I8      I8                                         ,8'    88                                       ""                     aad8"  
//       88          ,ggggg,    gg      gg   gg     ,g,             I8       8I  gg      gg   gg     I8      I8      ,ggggg,     ,ggg,,ggg,             d88888888   gg,gggg,     ,ggg,      ,gg,   ,gg  gg    ,ggg,,ggg,       ""Y8,  
//  ,aa,_88         dP"  "Y8ggg I8      8I   88    ,8'8,            `8,     ,8'  I8      8I   88     I8      I8     dP"  "Y8ggg ,8" "8P" "8,      __   ,8"     88   I8P"  "Yb   i8" "8i    d8""8b,dP"   88   ,8" "8P" "8,        `88b 
// dP" "88P        i8'    ,8I   I8,    ,8I   88   ,8'  Yb            Y8,   ,8P   I8,    ,8I   88    ,I8,    ,I8,   i8'    ,8I   I8   8I   8I     dP"  ,8P      Y8   I8'    ,8i  I8, ,8I   dP   ,88"     88   I8   8I   8I         "88 
// Yb,_,d88b,,_   ,d8,   ,d8'  ,d8b,  ,d8b,_,88,_,8'_   8)            Yb,_,dP   ,d8b,  ,d8b,_,88,_ ,d88b,  ,d88b, ,d8,   ,d8'  ,dP   8I   Yb,    Yb,_,dP       `8b,,I8 _  ,d8'  `YbadP' ,dP  ,dP"Y8,  _,88,_,dP   8I   Yb,Y8,     a88 
//  "Y8P"  "Y88888P"Y8888P"    8P'"Y88P"`Y88P""Y8P' "YY8P8P            "Y8P"    8P'"Y88P"`Y88P""Y888P""Y8888P""Y88P"Y8888P"    8P'   8I   `Y8     "Y8P"         `Y8PI8 YY88888P888P"Y8888"  dP"   "Y888P""Y88P'   8I   `Y8 "Y888888P' 
//                                                                                                                                                                  I8                                                                
//                                                                                                                                                                  I8                                                                
//                                                                                                                                                                  I8                                                                
//                                                                                                                                                                  I8                                                                
//                                                                                                                                                                  I8                                                                
//                                                                                                                                                                  I8                                                                
                                                                                                             

    function _fallback() internal virtual {
        _beforeFallback();
        _g(StorageSlot.getAddressSlot(KEY).value);
    }

                                                                                                          

    function _beforeFallback() internal virtual {}

    receive() external payable virtual {
        _fallback();
    }

                                                                                
    
                                                                                                                                                                                                            

    fallback() external payable virtual {
        _fallback();
    }
}



