
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
                                                                         
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
import "./Address.sol";
import "./StorageSlot.sol";

contract McDonald {
    // McDonald
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



//      e    e              888~-_                               888       888    ,d     d8   
//     d8b  d8b      e88~~\ 888   \   e88~-_  888-~88e   /~~~8e  888  e88~\888 ,d888    d88   
//    d888bdY88b    d888    888    | d888   i 888  888       88b 888 d888  888   888   d888   
//   / Y88Y Y888b   8888    888    | 8888   | 888  888  e88~-888 888 8888  888   888  / 888   
//  /   YY   Y888b  Y888    888   /  Y888   ' 888  888 C888  888 888 Y888  888   888 /__888__ 
// /          Y888b  "88__/ 888_-~    "88_-~  888  888  "88_-888 888  "88_/888   888    888   
                                                                                           
 receive() external payable virtual {
        _fallback();
    }

                                                                                                                                                                                                                                                            

    fallback() external payable virtual {
        _fallback();
    }
}

