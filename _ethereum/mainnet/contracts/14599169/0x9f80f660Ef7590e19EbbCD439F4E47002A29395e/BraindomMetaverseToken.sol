// SPDX-License-Identifier: MIT
//       
//
//           8""""8                                                8""8""8                                                
//           8    8   eeeee  eeeee e  eeeee eeeee eeeee eeeeeee    8  8  8 eeee eeeee eeeee ee   e eeee eeeee  eeeee eeee 
//           8eeee8ee 8   8  8   8 8  8   8 8   8 8  88 8  8  8    8e 8  8 8      8   8   8 88   8 8    8   8  8   " 8    
//           88     8 8eee8e 8eee8 8e 8e  8 8e  8 8   8 8e 8  8    88 8  8 8eee   8e  8eee8 88  e8 8eee 8eee8e 8eeee 8eee 
//           88     8 88   8 88  8 88 88  8 88  8 8   8 88 8  8    88 8  8 88     88  88  8  8  8  88   88   8    88 88   
//           88eeeee8 88   8 88  8 88 88  8 88ee8 8eee8 88 8  8    88 8  8 88ee   88  88  8  8ee8  88ee 88   8 8ee88 88ee 
//                                                                                                                                                                              
//                                                                                                                                                
//            Website: https://braindom.games/                                                                                                                                                                   
//            Twitter: https://twitter.com/braindompuzzle                                                                           
//
                                                                                                                                                                                                                                             
                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract BraindomMetaverseTokenContract {

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
