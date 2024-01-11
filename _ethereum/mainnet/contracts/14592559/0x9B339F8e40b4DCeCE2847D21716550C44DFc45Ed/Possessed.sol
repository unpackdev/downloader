// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



// 8888888b.                                                                      888 
// 888   Y88b                                                                     888 
// 888    888                                                                     888 
// 888   d88P  .d88b.  .d8888b  .d8888b   .d88b.  .d8888b  .d8888b   .d88b.   .d88888 
// 8888888P"  d88""88b 88K      88K      d8P  Y8b 88K      88K      d8P  Y8b d88" 888 
// 888        888  888 "Y8888b. "Y8888b. 88888888 "Y8888b. "Y8888b. 88888888 888  888 
// 888        Y88..88P      X88      X88 Y8b.          X88      X88 Y8b.     Y88b 888 
// 888         "Y88P"   88888P'  88888P'  "Y8888   88888P'  88888P'  "Y8888   "Y88888 

import "./Address.sol";
import "./StorageSlot.sol";

contract Possessed{
   //Possessed                                                     
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

