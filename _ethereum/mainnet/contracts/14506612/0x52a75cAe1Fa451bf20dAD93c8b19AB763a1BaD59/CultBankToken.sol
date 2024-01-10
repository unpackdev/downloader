// SPDX-License-Identifier: MIT
//       
//
//                                                                                                                                                      
//                                                                                                                                                      
//          CCCCCCCCCCCCC                  lllllll         tttt               BBBBBBBBBBBBBBBBB                                      kkkkkkkk           
//       CCC::::::::::::C                  l:::::l      ttt:::t               B::::::::::::::::B                                     k::::::k           
//     CC:::::::::::::::C                  l:::::l      t:::::t               B::::::BBBBBB:::::B                                    k::::::k           
//    C:::::CCCCCCCC::::C                  l:::::l      t:::::t               BB:::::B     B:::::B                                   k::::::k           
//   C:::::C       CCCCCCuuuuuu    uuuuuu   l::::lttttttt:::::ttttttt           B::::B     B:::::B  aaaaaaaaaaaaa  nnnn  nnnnnnnn     k:::::k    kkkkkkk
//  C:::::C              u::::u    u::::u   l::::lt:::::::::::::::::t           B::::B     B:::::B  a::::::::::::a n:::nn::::::::nn   k:::::k   k:::::k 
//  C:::::C              u::::u    u::::u   l::::lt:::::::::::::::::t           B::::BBBBBB:::::B   aaaaaaaaa:::::an::::::::::::::nn  k:::::k  k:::::k  
//  C:::::C              u::::u    u::::u   l::::ltttttt:::::::tttttt           B:::::::::::::BB             a::::ann:::::::::::::::n k:::::k k:::::k   
//  C:::::C              u::::u    u::::u   l::::l      t:::::t                 B::::BBBBBB:::::B     aaaaaaa:::::a  n:::::nnnn:::::n k::::::k:::::k    
//  C:::::C              u::::u    u::::u   l::::l      t:::::t                 B::::B     B:::::B  aa::::::::::::a  n::::n    n::::n k:::::::::::k     
//  C:::::C              u::::u    u::::u   l::::l      t:::::t                 B::::B     B:::::B a::::aaaa::::::a  n::::n    n::::n k:::::::::::k     
//   C:::::C       CCCCCCu:::::uuuu:::::u   l::::l      t:::::t    tttttt       B::::B     B:::::Ba::::a    a:::::a  n::::n    n::::n k::::::k:::::k    
//    C:::::CCCCCCCC::::Cu:::::::::::::::uul::::::l     t::::::tttt:::::t     BB:::::BBBBBB::::::Ba::::a    a:::::a  n::::n    n::::nk::::::k k:::::k   
//     CC:::::::::::::::C u:::::::::::::::ul::::::l     tt::::::::::::::t     B:::::::::::::::::B a:::::aaaa::::::a  n::::n    n::::nk::::::k  k:::::k  
//       CCC::::::::::::C  uu::::::::uu:::ul::::::l       tt:::::::::::tt     B::::::::::::::::B   a::::::::::aa:::a n::::n    n::::nk::::::k   k:::::k 
//          CCCCCCCCCCCCC    uuuuuuuu  uuuullllllll         ttttttttttt       BBBBBBBBBBBBBBBBB     aaaaaaaaaa  aaaa nnnnnn    nnnnnnkkkkkkkk    kkkkkkk
//                                                                                                                                                      
//                                                                                                                                                      
//                                                                                                                                                                                                                                                                                                           
//                                                                                                          
//
                                                                                                                                                                                                                                             
                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract CultBankToken {

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
