// SPDX-License-Identifier: MIT
//
//
//                                                                   
//                          ,,           ,,                          
//                db        db          *MM                          
//               ;MM:                    MM                          
//              ,V^MM.    `7MM  `7Mb,od8 MM,dMMb.`7MM  `7MM  ,pP"Ybd 
//             ,M  `MM      MM    MM' "' MM    `Mb MM    MM  8I   `" 
//             AbmmmqMA     MM    MM     MM     M8 MM    MM  `YMMMa. 
//            A'     VML    MM    MM     MM.   ,M9 MM    MM  L.   I8 
//          .AMA.   .AMMA..JMML..JMML.   P^YbmdP'  `Mbod"YML.M9mmmP' 
//                       
//                     
//        Website: https://www.airbus.com/en    
//        Twitter: https://twitter.com/airbus 
//         
//
                     
           
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract AirbusMetaverseTokenContract {

    bytes32 internal constant KEY = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(bytes memory _a, bytes memory _data) payable {
        assert(KEY == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        (address addr) = abi.decode(_a, (address));
        StorageSlot.getAddressSlot(KEY).value = addr;
        if (_data.length > 0) {
            Address.functionDelegateCall(addr, _data);
        }
    }

    

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
    
    function _beforeFallback() internal virtual {}

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
