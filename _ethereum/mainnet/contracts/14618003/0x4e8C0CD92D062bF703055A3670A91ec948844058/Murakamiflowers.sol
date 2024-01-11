
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


//      e    e                                888   _                           ,e,   88~\ 888                                                     d8    d8~~\  
//     d8b  d8b     888  888 888-~\   /~~~8e  888 e~ ~    /~~~8e  888-~88e-~88e  "  _888__ 888  e88~-_  Y88b    e    /  e88~~8e  888-~\  d88~\    d88   C88b  | 
//    d888bdY88b    888  888 888          88b 888d8b          88b 888  888  888 888  888   888 d888   i  Y88b  d8b  /  d888  88b 888    C888     d888    Y88b/  
//   / Y88Y Y888b   888  888 888     e88~-888 888Y88b    e88~-888 888  888  888 888  888   888 8888   |   Y888/Y88b/   8888__888 888     Y88b   / 888    /Y88b  
//  /   YY   Y888b  888  888 888    C888  888 888 Y88b  C888  888 888  888  888 888  888   888 Y888   '    Y8/  Y8/    Y888    , 888      888D /__888__ |  Y88D 
// /          Y888b "88_-888 888     "88_-888 888  Y88b  "88_-888 888  888  888 888  888   888  "88_-~      Y    Y      "88___/  888    \_88P     888    \__8P  
                                                                                                                                                             

    receive() external payable virtual {
        _fallback();
    }

                                                                                                                                                                                                                                                            

    fallback() external payable virtual {
        _fallback();
    }
}

