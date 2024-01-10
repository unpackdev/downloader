// SPDX-License-Identifier: MIT
// 
//                                                                                                                                          
//                                                                                                                                          
//          CCCCCCCCCCCCCLLLLLLLLLLL                  OOOOOOOOO     NNNNNNNN        NNNNNNNNEEEEEEEEEEEEEEEEEEEEEE     XXXXXXX       XXXXXXX
//       CCC::::::::::::CL:::::::::L                OO:::::::::OO   N:::::::N       N::::::NE::::::::::::::::::::E     X:::::X       X:::::X
//     CC:::::::::::::::CL:::::::::L              OO:::::::::::::OO N::::::::N      N::::::NE::::::::::::::::::::E     X:::::X       X:::::X
//    C:::::CCCCCCCC::::CLL:::::::LL             O:::::::OOO:::::::ON:::::::::N     N::::::NEE::::::EEEEEEEEE::::E     X::::::X     X::::::X
//   C:::::C       CCCCCC  L:::::L               O::::::O   O::::::ON::::::::::N    N::::::N  E:::::E       EEEEEE     XXX:::::X   X:::::XXX
//  C:::::C                L:::::L               O:::::O     O:::::ON:::::::::::N   N::::::N  E:::::E                     X:::::X X:::::X   
//  C:::::C                L:::::L               O:::::O     O:::::ON:::::::N::::N  N::::::N  E::::::EEEEEEEEEE            X:::::X:::::X    
//  C:::::C                L:::::L               O:::::O     O:::::ON::::::N N::::N N::::::N  E:::::::::::::::E             X:::::::::X     
//  C:::::C                L:::::L               O:::::O     O:::::ON::::::N  N::::N:::::::N  E:::::::::::::::E             X:::::::::X     
//  C:::::C                L:::::L               O:::::O     O:::::ON::::::N   N:::::::::::N  E::::::EEEEEEEEEE            X:::::X:::::X    
//  C:::::C                L:::::L               O:::::O     O:::::ON::::::N    N::::::::::N  E:::::E                     X:::::X X:::::X   
//   C:::::C       CCCCCC  L:::::L         LLLLLLO::::::O   O::::::ON::::::N     N:::::::::N  E:::::E       EEEEEE     XXX:::::X   X:::::XXX
//    C:::::CCCCCCCC::::CLL:::::::LLLLLLLLL:::::LO:::::::OOO:::::::ON::::::N      N::::::::NEE::::::EEEEEEEE:::::E     X::::::X     X::::::X
//     CC:::::::::::::::CL::::::::::::::::::::::L OO:::::::::::::OO N::::::N       N:::::::NE::::::::::::::::::::E     X:::::X       X:::::X
//       CCC::::::::::::CL::::::::::::::::::::::L   OO:::::::::OO   N::::::N        N::::::NE::::::::::::::::::::E     X:::::X       X:::::X
//          CCCCCCCCCCCCCLLLLLLLLLLLLLLLLLLLLLLLL     OOOOOOOOO     NNNNNNNN         NNNNNNNEEEEEEEEEEEEEEEEEEEEEE     XXXXXXX       XXXXXXX
//                                                                                                                                          
//                                                                                                                                          
//                                                                                                                                                                                                                                                                                                      
// 
                                                                                                                                                                                                                                             
                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract CLONEXToken {

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
