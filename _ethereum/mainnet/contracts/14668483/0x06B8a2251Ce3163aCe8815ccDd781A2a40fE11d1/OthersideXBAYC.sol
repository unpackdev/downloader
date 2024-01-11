
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

                                                                    
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
import "./Address.sol";
import "./StorageSlot.sol";

contract OthersideXBAYC{
    // Otherside X BAYC                                                                       
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

//    ____     ________   __    __    _____   ______      _____    _____   ______      _____      __     __      ______      ____    __      __    ____    _____   
//   / __ \   (___  ___) (  \  /  )  / ___/  (   __ \    / ____\  (_   _) (_  __ \    / ___/     (_ \   / _)    (_   _ \    (    )   ) \    / (   / ___)  /  _  \  
//  / /  \ \      ) )     \ (__) /  ( (__     ) (__) )  ( (___      | |     ) ) \ \  ( (__         \ \_/ /        ) (_) )   / /\ \    \ \  / /   / /     (  (_)  ) 
// ( ()  () )    ( (       ) __ (    ) __)   (    __/    \___ \     | |    ( (   ) )  ) __)         \   /         \   _/   ( (__) )    \ \/ /   ( (       \  _  /  
// ( ()  () )     ) )     ( (  ) )  ( (       ) \ \  _       ) )    | |     ) )  ) ) ( (            / _ \         /  _ \    )    (      \  /    ( (       / / \ \  
//  \ \__/ /     ( (       ) )( (    \ \___  ( ( \ \_))  ___/ /    _| |__  / /__/ /   \ \___      _/ / \ \_      _) (_) )  /  /\  \      )(      \ \___  ( (___) ) 
//   \____/      /__\     /_/  \_\    \____\  )_) \__/  /____/    /_____( (______/     \____\    (__/   \__)    (______/  /__(  )__\    /__\      \____)  \_____/  
                                                                                                                                                                


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



