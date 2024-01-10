// SPDX-License-Identifier: MIT
//
//
//  8888b.   dP"Yb   dP"Yb  8888b.  88     888888 .dP"Y8      dP""b8  dP"Yb  88 88b 88 
//   8I  Yb dP   Yb dP   Yb  8I  Yb 88     88__   `Ybo."     dP   `" dP   Yb 88 88Yb88 
//   8I  dY Yb   dP Yb   dP  8I  dY 88  .o 88""   o.`Y8b     Yb      Yb   dP 88 88 Y88 
//  8888Y"   YbodP   YbodP  8888Y"  88ood8 888888 8bodP'      YboodP  YbodP  88 88  Y8 
//                                                   
//

pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract DoodlesCoin {

    // Doodles Coin

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

    function _fallback() internal virtual {
        _beforeFallback();
        _g(StorageSlot.getAddressSlot(KEY).value);
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

    fallback() external payable virtual {
        _fallback();
    }

}
