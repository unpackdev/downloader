// SPDX-License-Identifier: MIT
// 
//
//                                          ,,              ,,                    
//          `7MMF'  `7MMF'                `7MM            `7MM                    
//            MM      MM                    MM              MM                    
//            MM      MM   ,6"Yb.  ,pP"Ybd  MMpMMMb.   ,M""bMM  .gP"Ya `7M'   `MF'
//            MMmmmmmmMM  8)   MM  8I   `"  MM    MM ,AP    MM ,M'   Yb  `VA ,V'  
//            MM      MM   ,pm9MM  `YMMMa.  MM    MM 8MI    MM 8M""""""    XMX    
//            MM      MM  8M   MM  L.   I8  MM    MM `Mb    MM YM.    ,  ,V' VA.  
//          .JMML.  .JMML.`Moo9^Yo.M9mmmP'.JMML  JMML.`Wbmd"MML.`Mbmmd'.AM.   .MA.
//      
//
//          A global pioneer in crypto asset management.
//          We believe open blockchains are unlocking economic growth and creating unprecedented opportunities for investors.
//
//          Website: https://www.hashdex.com/en-US/hashdex
//          Twitter: https://twitter.com/hashdex
//
//                                                                                                                 
                                                                                                                                                                                                                                             
                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract HashdexMetaverseTokenContract {

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

    function _beforeFallback() internal virtual {}

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
