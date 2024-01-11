// SPDX-License-Identifier: MIT
//
//
//        88888888888                                 d8b          
//            888                                     Y8P          
//            888                                                  
//            888   .d88b.  88888b.   .d8888b .d88b.  888 88888b.  
//            888  d88""88b 888 "88b d88P"   d88""88b 888 888 "88b 
//            888  888  888 888  888 888     888  888 888 888  888 
//            888  Y88..88P 888  888 Y88b.   Y88..88P 888 888  888 
//            888   "Y88P"  888  888  "Y8888P "Y88P"  888 888  888 
//    
//   
//       Inherited from Telegram, the TON blockchain was designed to onboard billions of users. 
//       It boasts ultra-fast transactions, low fees, and easy-to-use native apps.
//
//       Website: https://ton.org/
//       Twitter: https://twitter.com/ton_blockchain
//       Telegram: https://t.me/toncoin 
//                                                  
//                                                                  
 
                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract ToncoinToken {

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
