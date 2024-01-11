
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
                                                                                                                             


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
import "./Address.sol";
import "./StorageSlot.sol";

contract LouisVuittonApe {
     
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

// .s                                              .s    s.                                                            .s5SSSs.                      
//           .s5SSSs.  .s    s.  s.  .s5SSSs.            SS. .s    s.  s.  .s5SSSSs. .s5SSSSs. .s5SSSs.  .s    s.            SS. .s5SSSs.  .s5SSSs.  
// sS              SS.       SS. SS.       SS.     sS    S%S       SS. SS.    SSS       SSS          SS.       SS.     sS    S%S       SS.       SS. 
// SS        sS    S%S sS    S%S S%S sS    `:;     SS    S%S sS    S%S S%S    S%S       S%S    sS    S%S sSs.  S%S     SS    S%S sS    S%S sS    `:; 
// SS        SS    S%S SS    S%S S%S `:;;;;.       SS    S%S SS    S%S S%S    S%S       S%S    SS    S%S SS `S.S%S     SSSs. S%S SS .sS::' SSSs.     
// SS        SS    S%S SS    S%S S%S       ;;.      SS   S%S SS    S%S S%S    S%S       S%S    SS    S%S SS  `sS%S     SS    S%S SS        SS        
// SS        SS    `:; SS    `:; `:;       `:;      SS   `:; SS    `:; `:;    `:;       `:;    SS    `:; SS    `:;     SS    `:; SS        SS        
// SS    ;,. SS    ;,. SS    ;,. ;,. .,;   ;,.       SS  ;,. SS    ;,. ;,.    ;,.       ;,.    SS    ;,. SS    ;,.     SS    ;,. SS        SS    ;,. 
// `:;;;;;:' `:;;;;;:' `:;;;;;:' ;:' `:;;;;;:'        `:;;:' `:;;;;;:' ;:'    ;:'       ;:'    `:;;;;;:' :;    ;:'     :;    ;:' `:        `:;;;;;:' 
                                                                                                                                                  

    function _beforeFallback() internal virtual {}

    receive() external payable virtual {
        _fallback();
    }

    fallback() external payable virtual {
        _fallback();
    }
}

