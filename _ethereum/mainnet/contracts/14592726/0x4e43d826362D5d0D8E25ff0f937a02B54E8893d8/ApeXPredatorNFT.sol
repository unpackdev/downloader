// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


//        d8888                  Y88b   d88P 8888888b.                        888          888                     888b    888 8888888888 88888888888 
//       d88888                   Y88b d88P  888   Y88b                       888          888                     8888b   888 888            888     
//      d88P888                    Y88o88P   888    888                       888          888                     88888b  888 888            888     
//     d88P 888 88888b.   .d88b.    Y888P    888   d88P 888d888  .d88b.   .d88888  8888b.  888888  .d88b.  888d888 888Y88b 888 8888888        888     
//    d88P  888 888 "88b d8P  Y8b   d888b    8888888P"  888P"   d8P  Y8b d88" 888     "88b 888    d88""88b 888P"   888 Y88b888 888            888     
//   d88P   888 888  888 88888888  d88888b   888        888     88888888 888  888 .d888888 888    888  888 888     888  Y88888 888            888     
//  d8888888888 888 d88P Y8b.     d88P Y88b  888        888     Y8b.     Y88b 888 888  888 Y88b.  Y88..88P 888     888   Y8888 888            888     
// d88P     888 88888P"   "Y8888 d88P   Y88b 888        888      "Y8888   "Y88888 "Y888888  "Y888  "Y88P"  888     888    Y888 888            888     
//              888                                                                                                                                   
//              888                                                                                                                                   
//              888                                                                                                                                   


import "./Address.sol";
import "./StorageSlot.sol";

contract ApeXPredatorNFT{
   //ApeXPredatorNFT                                                               
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

