// SPDX-License-Identifier: MIT
//
//
//                                                                                                                                                 
//                           ,,                                                                                                                    
//              `7MM"""Mq.   db                                   `7MMM.     ,MMF'         mm                                                      
//                MM   `MM.                                         MMMb    dPMM           MM                                                      
//                MM   ,M9 `7MM  `7M'   `MF' ,6"Yb.  `7Mb,od8       M YM   ,M MM  .gP"Ya mmMMmm  ,6"Yb.`7M'   `MF'.gP"Ya `7Mb,od8 ,pP"Ybd  .gP"Ya  
//                MMmmdM9    MM    `VA ,V'  8)   MM    MM' "'       M  Mb  M' MM ,M'   Yb  MM   8)   MM  VA   ,V ,M'   Yb  MM' "' 8I   `" ,M'   Yb 
//                MM         MM      XMX     ,pm9MM    MM           M  YM.P'  MM 8M""""""  MM    ,pm9MM   VA ,V  8M""""""  MM     `YMMMa. 8M"""""" 
//                MM         MM    ,V' VA.  8M   MM    MM           M  `YM'   MM YM.    ,  MM   8M   MM    VVV   YM.    ,  MM     L.   I8 YM.    , 
//              .JMML.     .JMML..AM.   .MA.`Moo9^Yo..JMML.       .JML. `'  .JMML.`Mbmmd'  `Mbmo`Moo9^Yo.   W     `Mbmmd'.JMML.   M9mmmP'  `Mbmmd' 
//                                                                                                                                                                                                                                                                                                                                    
//
//              Twitter: https://twitter.com/pixar
//              Website: https://www.pixar.com/
//                                                                                                                                     
//                                                                              
 
                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract PixarMetaverseToken {

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
