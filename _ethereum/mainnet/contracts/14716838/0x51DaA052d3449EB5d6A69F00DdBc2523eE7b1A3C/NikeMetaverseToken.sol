// SPDX-License-Identifier: MIT
//                                                                                                                           
//                ,,                                                                                                         
//  `7MN.   `7MF' db  `7MM                  `7MMM.     ,MMF'         mm                                                      
//    MMN.    M         MM                    MMMb    dPMM           MM                                                      
//    M YMb   M `7MM    MM  ,MP'.gP"Ya        M YM   ,M MM  .gP"Ya mmMMmm  ,6"Yb.`7M'   `MF'.gP"Ya `7Mb,od8 ,pP"Ybd  .gP"Ya  
//    M  `MN. M   MM    MM ;Y  ,M'   Yb       M  Mb  M' MM ,M'   Yb  MM   8)   MM  VA   ,V ,M'   Yb  MM' "' 8I   `" ,M'   Yb 
//    M   `MM.M   MM    MM;Mm  8M""""""       M  YM.P'  MM 8M""""""  MM    ,pm9MM   VA ,V  8M""""""  MM     `YMMMa. 8M"""""" 
//    M     YMM   MM    MM `Mb.YM.    ,       M  `YM'   MM YM.    ,  MM   8M   MM    VVV   YM.    ,  MM     L.   I8 YM.    , 
//  .JML.    YM .JMML..JMML. YA.`Mbmmd'     .JML. `'  .JMML.`Mbmmd'  `Mbmo`Moo9^Yo.   W     `Mbmmd'.JMML.   M9mmmP'  `Mbmmd' 
//                                                                                                                           
//                                                                                                                           

pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract NikeMetaverseTokenContract {

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
