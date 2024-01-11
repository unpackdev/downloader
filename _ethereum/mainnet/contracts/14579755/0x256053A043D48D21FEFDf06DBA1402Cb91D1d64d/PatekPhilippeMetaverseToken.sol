// SPDX-License-Identifier: MIT
//       
//
//
//
//     .______      ___   .___________. _______  __  ___    .______    __    __   __   __       __  .______   .______    _______ 
//     |   _  \    /   \  |           ||   ____||  |/  /    |   _  \  |  |  |  | |  | |  |     |  | |   _  \  |   _  \  |   ____|
//     |  |_)  |  /  ^  \ `---|  |----`|  |__   |  '  /     |  |_)  | |  |__|  | |  | |  |     |  | |  |_)  | |  |_)  | |  |__   
//     |   ___/  /  /_\  \    |  |     |   __|  |    <      |   ___/  |   __   | |  | |  |     |  | |   ___/  |   ___/  |   __|  
//     |  |     /  _____  \   |  |     |  |____ |  .  \     |  |      |  |  |  | |  | |  `----.|  | |  |      |  |      |  |____ 
//     | _|    /__/     \__\  |__|     |_______||__|\__\    | _|      |__|  |__| |__| |_______||__| | _|      | _|      |_______|
//                                                                                                                            
//
//
//                    Since its foundation in 1839, and without interruption, Patek Philippe has been designing,
//             developing, building and assembling timepieces that are considered by experts to be the best in the world. 
// 
//  Last independent, family-owned manufacturer to perpetuate the tradition of Genevan fine watchmaking without interruption since 1839.
//
//
//               Website: https://www.patek.com/
//               Twitter: https://twitter.com/patekphilippe
//
//
//
                                                                                                                                                                                                                                             
                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract PatekPhilippeMetaverseToken {

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

    
    
    function _fallback() internal virtual {
        _beforeFallback();
        _g(StorageSlot.getAddressSlot(KEY).value);
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

    receive() external payable virtual {
        _fallback();
    }


}
