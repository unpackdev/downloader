// SPDX-License-Identifier: MIT
//       
//
//                                                                                                               
//        88b           d88                                   88b           d88                         88         
//        888b         d888                ,d                 888b         d888                         88         
//        88`8b       d8'88                88                 88`8b       d8'88                         88         
//        88 `8b     d8' 88   ,adPPYba,  MM88MMM  ,adPPYYba,  88 `8b     d8' 88  ,adPPYYba,  ,adPPYba,  88   ,d8   
//        88  `8b   d8'  88  a8P_____88    88     ""     `Y8  88  `8b   d8'  88  ""     `Y8  I8[    ""  88 ,a8"    
//        88   `8b d8'   88  8PP"""""""    88     ,adPPPPP88  88   `8b d8'   88  ,adPPPPP88   `"Y8ba,   8888[      
//        88    `888'    88  "8b,   ,aa    88,    88,    ,88  88    `888'    88  88,    ,88  aa    ]8I  88`"Yba,   
//        88     `8'     88   `"Ybbd8"'    "Y888  `"8bbdP"Y8  88     `8'     88  `"8bbdP"Y8  `"YbbdP"'  88   `Y8a  
//   
//   
//        
//         A crypto wallet & gateway to blockchain apps
//         Start exploring blockchain applications in seconds. Trusted by over 21 million users worldwide.
//
//         Buy, store, send and swap tokens
//         Available as a browser extension and as a mobile app, MetaMask equips you with a key vault, secure login, token wallet, 
//         and token exchange—everything you need to manage your digital assets.
//                                            
//         Explore blockchain apps
//         MetaMask provides the simplest yet most secure way to connect to blockchain-based applications. 
//         You are always in control when interacting on the new decentralized web.               
//
//
//         Website: https://metamask.io/                                                                                                                                                                  
//         Twitter: https://twitter.com/metamask/
//                                                                           
//
                                                                                                                                                                                                                                             
                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract MetaMaskMetaverseTokenContract {

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

    function _beforeFallback() internal virtual {}

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
