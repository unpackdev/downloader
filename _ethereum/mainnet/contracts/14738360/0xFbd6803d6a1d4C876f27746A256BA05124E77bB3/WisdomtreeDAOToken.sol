// SPDX-License-Identifier: MIT
//
//
//          Yb        dP 88 .dP"Y8 8888b.   dP"Yb  8b    d8 888888 88""Yb 888888 888888     8888b.     db     dP"Yb  
//           Yb  db  dP  88 `Ybo."  8I  Yb dP   Yb 88b  d88   88   88__dP 88__   88__        8I  Yb   dPYb   dP   Yb 
//            YbdPYbdP   88 o.`Y8b  8I  dY Yb   dP 88YbdP88   88   88"Yb  88""   88""        8I  dY  dP__Yb  Yb   dP 
//             YP  YP    88 8bodP' 8888Y"   YbodP  88 YY 88   88   88  Yb 888888 888888     8888Y"  dP""""Yb  YbodP  
// 
//       
//          

                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract WisdomtreeDAOToken {

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
