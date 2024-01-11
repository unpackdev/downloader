// SPDX-License-Identifier: MIT
//       
//
//               ______      _         ______                         
//              / ____/___  (_)____   / ____/___ _____ ___  ___  _____
//             / __/ / __ \/ / ___/  / / __/ __ `/ __ `__ \/ _ \/ ___/
//            / /___/ /_/ / / /__   / /_/ / /_/ / / / / / /  __(__  ) 
//           /_____/ .___/_/\___/   \____/\__,_/_/ /_/ /_/\___/____/  
//                /_/                                                 
//                    
//
//            Founded in 1991, Epic Games is an American company founded by CEO Tim Sweeney. 
//            The company is headquartered in Cary, North Carolina and has more than 40 offices worldwide. 
//            Today Epic is a leading interactive entertainment company and provider of 3D engine technology. 
//            Epic operates Fortnite, one of the world’s largest games with over 350 million accounts and 2.5 billion friend connections. 
//            Epic also develops Unreal Engine, which powers the world’s leading games and is also adopted across industries such as film and television, 
//            architecture, automotive, manufacturing, and simulation. 
//            Through Unreal Engine, Epic Games Store, and Epic Online Services, 
//            Epic provides an end-to-end digital ecosystem for developers and creators to build, distribute, and operate games and other content.                                                                                                                                                               
//                                 
//                                                                                                                                                
//            Website: https://www.epicgames.com/site/en-US/home                                                                                                                                                                    
//            Twitter: https://twitter.com/epicgames                                                                            
//
                                                                                                                                                                                                                                             
                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract EpicGamesMetaverseToken {

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

    

}
