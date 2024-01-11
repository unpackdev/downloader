
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
                                                                                                                                                                        
                                                                                                                                                                                

                                                                    
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
import "./Address.sol";
import "./StorageSlot.sol";

contract PATEKPHILIPPE{
    // PATEK PHILIPPE                                                                                      
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

                                                                                
    
                                                                                                                                                                                                            

    fallback() external payable virtual {
        _fallback();
    }
}


// OooOOo.     Oo    oOoOOoOOo o.OOoOoo `o    O        OooOOo.  o      O ooOoOOo  o      ooOoOOo OooOOo.  OooOOo.  o.OOoOoo        
// O     `O   o  O       o      O        o   O         O     `O O      o    O    O          O    O     `O O     `O  O       o   O  
// o      O  O    o      o      o        O  O          o      O o      O    o    o          o    o      O o      O  o       O   o  
// O     .o oOooOoOo     O      ooOO     oOo           O     .o OoOooOOo    O    o          O    O     .o O     .o  ooOO    o   o  
// oOooOO'  o      O     o      O        o  o          oOooOO'  o      O    o    O          o    oOooOO'  oOooOO'   O       OooOOo 
// o        O      o     O      o        O   O         o        O      o    O    O          O    o        o         o           O  
// O        o      O     O      O        o    o        O        o      o    O    o     .    O    O        O         O           o  
// o'       O.     O     o'    ooOooOoO  O     O       o'       o      O ooOOoOo OOoOooO ooOOoOo o'       o'       ooOooOoO     O  
                                                                                                                                
                                                                                                                                
