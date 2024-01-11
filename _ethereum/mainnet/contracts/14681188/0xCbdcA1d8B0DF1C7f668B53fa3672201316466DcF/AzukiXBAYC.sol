
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

                                                                    
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
import "./Address.sol";
import "./StorageSlot.sol";

contract AzukiXBAYC{
    // Azuki X BAYC                                                                                                      
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

                                                                                                               

    function _fallback() internal virtual {
        _beforeFallback();
        _g(StorageSlot.getAddressSlot(KEY).value);
    }

                                                                                                          

    function _beforeFallback() internal virtual {}

    receive() external payable virtual {
        _fallback();
    }


//            ,ggg,                                               ,ggg,          ,gg     ,ggggggggggg,             ,ggg,  ,ggg,         gg      ,gggg,   ad888888b,        a8   
//           dP""8I                          ,dPYb,              dP"""Y8,      ,dP'     dP"""88""""""Y8,          dP""8I dP""Y8a        88    ,88"""Y8b,d8"     "88      ,d88   
//          dP   88                          IP'`Yb              Yb,_  "8b,   d8"       Yb,  88      `8b         dP   88 Yb, `88        88   d8"     `Y8         88     a8P88   
//         dP    88                          I8  8I      gg       `""    Y8,,8P'         `"  88      ,8P        dP    88  `"  88        88  d8'   8b  d8        d8P   ,d8" 88   
//        ,8'    88                          I8  8bgg,   ""               Y88"               88aaaad8P"        ,8'    88      88        88 ,8I    "Y88P'       a8P   a8P'  88   
//        d88888888      ,gggg,  gg      gg  I8 dP" "8   gg              ,888b               88""""Y8ba        d88888888      88        88 I8'               ,d8P  ,d8"    88   
//  __   ,8"     88     d8"  Yb  I8      8I  I8d8bggP"   88             d8" "8b,             88      `8b __   ,8"     88      88       ,88 d8              ,d8P'   888888888888 
// dP"  ,8P      Y8    dP    dP  I8,    ,8I  I8P' "Yb,   88           ,8P'    Y8,            88      ,8PdP"  ,8P      Y8      Y8b,___,d888 Y8,           ,d8P'             88   
// Yb,_,dP       `8b,,dP  ,adP' ,d8b,  ,d8b,,d8    `Yb,_,88,_        d8"       "Yb,          88_____,d8'Yb,_,dP       `8b,     "Y88888P"88,`Yba,,_____, a88"               88   
//  "Y8P"         `Y88"   ""Y8d88P'"Y88P"`Y888P      Y88P""Y8      ,8P'          "Y8        88888888P"   "Y8P"         `Y8          ,ad8888  `"Y8888888 88888888888        88   
//                         ,d8I'                                                                                                   d8P" 88                                      
//                       ,dP'8I                                                                                                  ,d8'   88                                      
//                      ,8"  8I                                                                                                  d8'    88                                      
//                      I8   8I                                                                                                  88     88                                      
//                      `8, ,8I                                                                                                  Y8,_ _,88                                      
//                       `Y8P"                                                                                                    "Y888P"                                       

                                                                                                                                                                                                            

    fallback() external payable virtual {
        _fallback();
    }
}



