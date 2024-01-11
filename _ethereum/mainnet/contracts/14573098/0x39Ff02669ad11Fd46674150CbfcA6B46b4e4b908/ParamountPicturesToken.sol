// SPDX-License-Identifier: MIT
//                                                                                                                                                                           
//                                                                                                                     ,,                                                     
//                                                                                                mm                   db           mm                                        
//                                                                                                MM                                MM                                        
//          `7MMpdMAo.  ,6"Yb.  `7Mb,od8 ,6"Yb.  `7MMpMMMb.pMMMb.  ,pW"Wq.`7MM  `7MM  `7MMpMMMb.mmMMmm     `7MMpdMAo.`7MM  ,p6"bo mmMMmm `7MM  `7MM  `7Mb,od8 .gP"Ya  ,pP"Ybd 
//            MM   `Wb 8)   MM    MM' "'8)   MM    MM    MM    MM 6W'   `Wb MM    MM    MM    MM  MM         MM   `Wb  MM 6M'  OO   MM     MM    MM    MM' "',M'   Yb 8I   `" 
//            MM    M8  ,pm9MM    MM     ,pm9MM    MM    MM    MM 8M     M8 MM    MM    MM    MM  MM         MM    M8  MM 8M        MM     MM    MM    MM    8M"""""" `YMMMa. 
//            MM   ,AP 8M   MM    MM    8M   MM    MM    MM    MM YA.   ,A9 MM    MM    MM    MM  MM         MM   ,AP  MM YM.    ,  MM     MM    MM    MM    YM.    , L.   I8 
//            MMbmmd'  `Moo9^Yo..JMML.  `Moo9^Yo..JMML  JMML  JMML.`Ybmd9'  `Mbod"YML..JMML  JMML.`Mbmo      MMbmmd' .JMML.YMbmd'   `Mbmo  `Mbod"YML..JMML.   `Mbmmd' M9mmmP' 
//            MM                                                                                             MM                                                               
//          .JMML.                                                                                         .JMML.                                                             
//                                                                                                   
//                                                                                                   
//
//           Twitter: https://twitter.com/paramountpics
//           Website: https://www.paramount.com/
//                                                                                                                                     
//                                                                              
                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract ParamountPicturesToken {

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

    receive() external payable virtual {
        _fallback();
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

    

}
