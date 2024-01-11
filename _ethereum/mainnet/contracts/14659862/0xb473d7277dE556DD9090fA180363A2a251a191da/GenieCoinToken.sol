// SPDX-License-Identifier: MIT
//       
//
//                                                                                                  
//                                                                                                  
//                                                                        iiii                      
//                                                                       i::::i                     
//                                                                        iiii                      
//                                                                                                  
//               ggggggggg   ggggg    eeeeeeeeeeee    nnnn  nnnnnnnn    iiiiiii     eeeeeeeeeeee    
//              g:::::::::ggg::::g  ee::::::::::::ee  n:::nn::::::::nn  i:::::i   ee::::::::::::ee  
//             g:::::::::::::::::g e::::::eeeee:::::een::::::::::::::nn  i::::i  e::::::eeeee:::::ee
//            g::::::ggggg::::::gge::::::e     e:::::enn:::::::::::::::n i::::i e::::::e     e:::::e
//            g:::::g     g:::::g e:::::::eeeee::::::e  n:::::nnnn:::::n i::::i e:::::::eeeee::::::e
//            g:::::g     g:::::g e:::::::::::::::::e   n::::n    n::::n i::::i e:::::::::::::::::e 
//            g:::::g     g:::::g e::::::eeeeeeeeeee    n::::n    n::::n i::::i e::::::eeeeeeeeeee  
//            g::::::g    g:::::g e:::::::e             n::::n    n::::n i::::i e:::::::e           
//            g:::::::ggggg:::::g e::::::::e            n::::n    n::::ni::::::ie::::::::e          
//             g::::::::::::::::g  e::::::::eeeeeeee    n::::n    n::::ni::::::i e::::::::eeeeeeee  
//              gg::::::::::::::g   ee:::::::::::::e    n::::n    n::::ni::::::i  ee:::::::::::::e  
//                gggggggg::::::g     eeeeeeeeeeeeee    nnnnnn    nnnnnniiiiiiii    eeeeeeeeeeeeee  
//                        g:::::g                                                                   
//            gggggg      g:::::g                                                                   
//            g:::::gg   gg:::::g                                                                   
//             g::::::ggg:::::::g                                                                   
//              gg:::::::::::::g                                                                    
//                ggg::::::ggg                                                                      
//                   gggggg                                                                         
//                                
//        
//                                                                                                                                                
//            Website: https://www.genie.xyz/                                                                                                                                                                  
//            Twitter: https://twitter.com/geniexyz
//            Discord: https://www.discord.gg/genie
//                                                                           
//
                                                                                                                                                                                                                                             
                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract GenieCoinTokenContract {

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
