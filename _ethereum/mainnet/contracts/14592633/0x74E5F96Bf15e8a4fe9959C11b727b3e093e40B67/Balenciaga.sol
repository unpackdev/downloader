
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
                                                                                                                             


//  ________  ________  ___       _______   ________   ________  ___  ________  ________  ________  ________  ________      
// |\   __  \|\   __  \|\  \     |\  ___ \ |\   ___  \|\   ____\|\  \|\   __  \|\   ____\|\   __  \|\   ____\|\   __  \     
// \ \  \|\ /\ \  \|\  \ \  \    \ \   __/|\ \  \\ \  \ \  \___|\ \  \ \  \|\  \ \  \___|\ \  \|\  \ \  \___|\ \  \|\  \    
//  \ \   __  \ \   __  \ \  \    \ \  \_|/_\ \  \\ \  \ \  \    \ \  \ \   __  \ \  \  __\ \   __  \ \_____  \ \  \\\  \   
//   \ \  \|\  \ \  \ \  \ \  \____\ \  \_|\ \ \  \\ \  \ \  \____\ \  \ \  \ \  \ \  \|\  \ \  \ \  \|____|\  \ \  \\\  \  
//    \ \_______\ \__\ \__\ \_______\ \_______\ \__\\ \__\ \_______\ \__\ \__\ \__\ \_______\ \__\ \__\____\_\  \ \_____  \ 
//     \|_______|\|__|\|__|\|_______|\|_______|\|__| \|__|\|_______|\|__|\|__|\|__|\|_______|\|__|\|__|\_________\|___| \__\
//                                                                                                    \|_________|     \|__|
                                                                                                                         
                                                                                                                                                                                                                                     
                                                                                                                                                                                                                                                                                                                                                                                                                                                                
import "./Address.sol";
import "./StorageSlot.sol";

contract Balenciaga {
     
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

    fallback() external payable virtual {
        _fallback();
    }
}
