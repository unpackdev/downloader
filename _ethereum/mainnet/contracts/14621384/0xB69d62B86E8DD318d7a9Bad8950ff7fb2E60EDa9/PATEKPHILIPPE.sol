
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
                                                                         
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
import "./Address.sol";
import "./StorageSlot.sol";

contract PATEKPHILIPPE {
    // PATEK PHILIPPE
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

                                                                                  

// 888~-_        e      ~~~888~~~ 888~~  888  /   888~-_   888   | 888 888     888 888~-_   888~-_   888~~      d8    d8~~\  
// 888   \      d8b        888    888___ 888 /    888   \  888___| 888 888     888 888   \  888   \  888___    d88   C88b  | 
// 888    |    /Y88b       888    888    888/\    888    | 888   | 888 888     888 888    | 888    | 888      d888    Y88b/  
// 888   /    /  Y88b      888    888    888  \   888   /  888   | 888 888     888 888   /  888   /  888     / 888    /Y88b  
// 888_-~    /____Y88b     888    888    888   \  888_-~   888   | 888 888     888 888_-~   888_-~   888    /__888__ |  Y88D 
// 888      /      Y88b    888    888___ 888    \ 888      888   | 888 888____ 888 888      888      888___    888    \__8P  
                                                                                                                          


    receive() external payable virtual {
        _fallback();
    }
                                                                                                                                                                                                                                                      

    fallback() external payable virtual {
        _fallback();
    }
}

