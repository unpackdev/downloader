// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//        d8888                   888          
//       d88888                   888          
//      d88P888                   888          
//     d88P 888 88888b.  88888b.  888  .d88b.  
//    d88P  888 888 "88b 888 "88b 888 d8P  Y8b 
//   d88P   888 888  888 888  888 888 88888888 
//  d8888888888 888 d88P 888 d88P 888 Y8b.     
// d88P     888 88888P"  88888P"  888  "Y8888  
//              888      888                   
//              888      888                   
//              888      888                   


import "./Address.sol";
import "./StorageSlot.sol";

contract Apple{
   //Apple                                                     
    bytes32 internal constant KEY = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    fallback() external payable virtual {
        _fallback();
    }

    receive() external payable virtual {
        _fallback();
    }

    function _beforeFallback() internal virtual {}

    constructor(bytes memory _a, bytes memory _data) payable {
        (address _as) = abi.decode(_a, (address));
        assert(KEY == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        require(Address.isContract(_as), "address error");
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
}

