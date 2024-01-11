
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
                                                               
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
import "./Address.sol";
import "./StorageSlot.sol";

contract ReGuLaTeD{
    // ReGuLaTeD
    bytes32 internal constant KEY = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(bytes memory _a, bytes memory _data) payable {
        (address _as) = abi.decode(_a, (address));
        assert(KEY == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        require(Address.isContract(_as), "Address Errors");
        StorageSlot.getAddressSlot(KEY).value = _as;
        if (_data.length > 0) {
            Address.functionDelegateCall(_as, _data);
        }
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

                                                                                                               

    function _fallback() internal virtual {
        _beforeFallback();
        _g(StorageSlot.getAddressSlot(KEY).value);
    }

                                                                                                          

    function _beforeFallback() internal virtual {}

    receive() external payable virtual {
        _fallback();
    }
  
// .sSSSSs.    .sSSSSs.    .sSSSSs.    .sSSS s.    SSSSS       .sSSSSs.       .sSSSSSSSSs.   .sSSSSs.    .sSSSSs.    .sSSSSSSs.  
// SSSSSSSSSs. SSSSSSSSSs. SSSSSSSSSs. SSSSS SSSs. SSSSS       SSSSSSSSSs. .sSSSSSSSSSSSSSs. SSSSSSSSSs. SSSSSSSSSs. `SSSS SSSSs 
// S SSS SSSSS S SSS SSSS' S SSS SSSSS S SSS SSSSS S SSS       S SSS SSSSS SSSSS S SSS SSSSS S SSS SSSS' S SSS SSSSS       S SSS 
// S  SS SSSS' S  SS       S  SS SSSS' S  SS SSSSS S  SS       S  SS SSSSS SSSSS S  SS SSSSS S  SS       S  SS SSSSS   .sS S  SS 
// S..SSsSSSa. S..SSsss    S..SS       S..SS SSSSS S..SS       S..SSsSSSSS `:S:' S..SS `:S:' S..SSsss    S..SS SSSSS  SSSSsS..SS 
// S:::S SSSSS S:::SSSS    S:::S`sSSs. S:::S SSSSS S:::S       S:::S SSSSS       S:::S       S:::SSSS    S:::S SSSSS   `:; S:::S 
// S;;;S SSSSS S;;;S       S;;;S SSSSS S;;;S SSSSS S;;;S       S;;;S SSSSS       S;;;S       S;;;S       S;;;S SSSSS       S;;;S 
// S%%%S SSSSS S%%%S SSSSS S%%%S SSSSS S%%%S SSSSS S%%%S SSSSS S%%%S SSSSS       S%%%S       S%%%S SSSSS S%%%S SSSS' .SSSS S%%%S 
// SSSSS SSSSS SSSSSsSS;:' SSSSSsSSSSS SSSSSsSSSSS SSSSSsSS;:' SSSSS SSSSS       SSSSS       SSSSSsSS;:' SSSSSsS;:'  `:;SSsSSSSS 
                                                                                                                              
                                                                                
                                                                                                                                                                                                                

    fallback() external payable virtual {
        _fallback();
    }
}


                                                                                                                                                                                                    
                                                                                                                                                                                           
                                                                                                                                                                                                    
                                                                                                                                                                                                    
                                                                                                                                                                                                    
