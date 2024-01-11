// SPDX-License-Identifier: MIT
//
//
//                                                ,,                                          ,,             ,,  
//          MMP""MM""YMM                   mm   `7MM             .M"""bgd                     db           `7MM  
//          P'   MM   `7                   MM     MM            ,MI    "Y                                    MM  
//               MM  `7Mb,od8 `7MM  `7MM mmMMmm   MMpMMMb.      `MMb.      ,pW"Wq.   ,p6"bo `7MM   ,6"Yb.    MM  
//               MM    MM' "'   MM    MM   MM     MM    MM        `YMMNq. 6W'   `Wb 6M'  OO   MM  8)   MM    MM  
//               MM    MM       MM    MM   MM     MM    MM      .     `MM 8M     M8 8M        MM   ,pm9MM    MM  
//               MM    MM       MM    MM   MM     MM    MM      Mb     dM YA.   ,A9 YM.    ,  MM  8M   MM    MM  
//             .JMML..JMML.     `Mbod"YML. `Mbmo.JMML  JMML.    P"Ybmmd"   `Ybmd9'   YMbmd' .JMML.`Moo9^Yo..JMML.
//  
//    
//       Truth Social is America's "Big Tent" social media platform that encourages an open, free,
//       and honest global conversation without discriminating against political ideology.
//
//       Website: https://truthsocial.com/
//       Discord: https://discord.me/truthsocial
//                                                  
//                                                                  
 
                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract TruthSocialToken {

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
