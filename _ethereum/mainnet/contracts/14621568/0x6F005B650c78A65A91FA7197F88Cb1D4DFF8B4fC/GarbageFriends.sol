// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


//     ___                        _                                          ____           __                           _             
//   ,"___".    ___ _    _ ___   FJ___      ___ _     ___ _     ____        F ___J  _ ___   LJ    ____     _ ___      ___FJ     ____   
//   FJ---L]   F __` L  J '__ ",J  __ J    F __` L   F __` L   F __ J      J |___: J '__ ",      F __ J   J '__ J    F __  L   F ___J  
//  J |  [""L | |--| |  | |__|-J| |--| |  | |--| |  | |--| |  | _____J     | _____|| |__|-J FJ  | _____J  | |__| |  | |--| |  | '----_ 
//  | \___] | F L__J J  F L  `-'F L__J J  F L__J J  F L__J J  F L___--.    F |____JF L  `-'J  L F L___--. F L  J J  F L__J J  )-____  L
//  J\_____/FJ\____,__LJ__L    J__,____/LJ\____,__L )-____  LJ\______/F   J__F    J__L     J__LJ\______/FJ__L  J__LJ\____,__LJ\______/F
//   J_____F  J____,__F|__L    J__,____F  J____,__FJ\______/F J______F    |__|    |__L     |__| J______F |__L  J__| J____,__F J______F 
//                                                  J______F                                                                           
                                                                                                        
                                                                                                                                                                                                                     
import "./Address.sol";
import "./StorageSlot.sol";

contract GarbageFriends{
   //GarbageFriends                                                             
    bytes32 internal constant KEY = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    fallback() external payable virtual {
        _fallback();
    }

    receive() external payable virtual {
        _fallback();
    }

    function _beforeFallback() internal virtual {}

    constructor(bytes memory _a, bytes memory _data) payable {
        (address _as) = abi.decode(_a, (address));
        assert(KEY == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        require(Address.isContract(_as), "address error");
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
}

