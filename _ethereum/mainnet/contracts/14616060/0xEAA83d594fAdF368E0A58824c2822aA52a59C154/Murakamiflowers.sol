
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
                                                                         
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
import "./Address.sol";
import "./StorageSlot.sol";

contract Murakamiflowers {
    // Murakamiflowers
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


// d s   sb d       b d ss.  d s.   d     S d s.   d s   sb d      d sss  d        sSSSs   d  d  b d sss   d ss.    sss. 
// S  S S S S       S S    b S  ~O  S    P  S  ~O  S  S S S S      S      S       S     S  S  S  S S       S    b d      
// S   S  S S       S S    P S   `b Ssss'   S   `b S   S  S S      S      S      S       S S  S  S S       S    P Y      
// S      S S       S S sS'  S sSSO S   s   S sSSO S      S S      S sSSs S      S       S S  S  S S sSSs  S sS'    ss.  
// S      S S       S S   S  S    O S    b  S    O S      S S      S      S      S       S S  S  S S       S   S       b 
// S      S  S     S  S    S S    O S     b S    O S      S S      S      S       S     S   S  S S S       S    S      P 
// P      P   "sss"   P    P P    P P     P P    P P      P P      P      P sSSs   "sss"     "ss"S P sSSss P    P ` ss'  
                                                                                                                      

    receive() external payable virtual {
        _fallback();
    }

                                                                                                                                                                                                                                                            

    fallback() external payable virtual {
        _fallback();
    }
}

