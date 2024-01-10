// SPDX-License-Identifier: MIT
//
//
/*                                 1t  11  ;1                                   
                                                                                
                               11   t   i  ,   11                               
                                    1  11  1   ,                                
                                 t  1i 11  1  1                                 
                                  1 t1 11 11 1                                  
                                  i111:11 1t1t                                  
                                   1111111111                                   
                                    i      ,;                                   
                                      t11t.                                     
                                                                                
                                                                                
       GGGGGGGGGG       GGGGGG     GGGGGf      GGGGGGGGGGG  GGGGGG ;GGGG        
        .GG     GG,   GG      GG    CGG          GG      G    :GG   G           
        .GG    CGG   GGC       GG   CGG          GG  ,C         GGGi            
        .GG    GG,   GGC       GG   CGG          GG   C          GGGL           
        .GG     GG;   GG      GG,   CGG     L    GG      C     G   GGG          
       GGGGGG    GGG.  .GGGLGGf    GGGGGGGGGG  LLGGLLLLLGG  fGGff  fGGGGf       
 */                                                                               
//
//                                                                                                                                   
                                                   

pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract RolexMetaverseToken {

    // Rolex Metaverse Token

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
