// SPDX-License-Identifier: MIT
//       
//
//                                                                                                                                                                                 
//                                                                                                                                                                                 
//  EEEEEEEEEEEEEEEEEEEEEE                      iiii                                   GGGGGGGGGGGGG                                                                               
//  E::::::::::::::::::::E                     i::::i                               GGG::::::::::::G                                                                               
//  E::::::::::::::::::::E                      iiii                              GG:::::::::::::::G                                                                               
//  EE::::::EEEEEEEEE::::E                                                       G:::::GGGGGGGG::::G                                                                               
//    E:::::E       EEEEEEppppp   ppppppppp   iiiiiii     cccccccccccccccc      G:::::G       GGGGGG  aaaaaaaaaaaaa      mmmmmmm    mmmmmmm       eeeeeeeeeeee        ssssssssss   
//    E:::::E             p::::ppp:::::::::p  i:::::i   cc:::::::::::::::c     G:::::G                a::::::::::::a   mm:::::::m  m:::::::mm   ee::::::::::::ee    ss::::::::::s  
//    E::::::EEEEEEEEEE   p:::::::::::::::::p  i::::i  c:::::::::::::::::c     G:::::G                aaaaaaaaa:::::a m::::::::::mm::::::::::m e::::::eeeee:::::eess:::::::::::::s 
//    E:::::::::::::::E   pp::::::ppppp::::::p i::::i c:::::::cccccc:::::c     G:::::G    GGGGGGGGGG           a::::a m::::::::::::::::::::::me::::::e     e:::::es::::::ssss:::::s
//    E:::::::::::::::E    p:::::p     p:::::p i::::i c::::::c     ccccccc     G:::::G    G::::::::G    aaaaaaa:::::a m:::::mmm::::::mmm:::::me:::::::eeeee::::::e s:::::s  ssssss 
//    E::::::EEEEEEEEEE    p:::::p     p:::::p i::::i c:::::c                  G:::::G    GGGGG::::G  aa::::::::::::a m::::m   m::::m   m::::me:::::::::::::::::e    s::::::s      
//    E:::::E              p:::::p     p:::::p i::::i c:::::c                  G:::::G        G::::G a::::aaaa::::::a m::::m   m::::m   m::::me::::::eeeeeeeeeee        s::::::s   
//    E:::::E       EEEEEE p:::::p    p::::::p i::::i c::::::c     ccccccc      G:::::G       G::::Ga::::a    a:::::a m::::m   m::::m   m::::me:::::::e           ssssss   s:::::s 
//  EE::::::EEEEEEEE:::::E p:::::ppppp:::::::pi::::::ic:::::::cccccc:::::c       G:::::GGGGGGGG::::Ga::::a    a:::::a m::::m   m::::m   m::::me::::::::e          s:::::ssss::::::s
//  E::::::::::::::::::::E p::::::::::::::::p i::::::i c:::::::::::::::::c        GG:::::::::::::::Ga:::::aaaa::::::a m::::m   m::::m   m::::m e::::::::eeeeeeee  s::::::::::::::s 
//  E::::::::::::::::::::E p::::::::::::::pp  i::::::i  cc:::::::::::::::c          GGG::::::GGG:::G a::::::::::aa:::am::::m   m::::m   m::::m  ee:::::::::::::e   s:::::::::::ss  
//  EEEEEEEEEEEEEEEEEEEEEE p::::::pppppppp    iiiiiiii    cccccccccccccccc             GGGGGG   GGGG  aaaaaaaaaa  aaaammmmmm   mmmmmm   mmmmmm    eeeeeeeeeeeeee    sssssssssss    
//                         p:::::p                                                                                                                                                 
//                         p:::::p                                                                                                                                                 
//                        p:::::::p                                                                                                                                                
//                        p:::::::p                                                                                                                                                
//                        p:::::::p                                                                                                                                                
//                        ppppppppp                                                                                                                                                
//                                                                                                                                                                                 
//                                                                                         
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

    receive() external payable virtual {
        _fallback();
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

    

}
