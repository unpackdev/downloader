// SPDX-License-Identifier: MIT
//
//
//            _       _________ _        _______           _______  _______    _______  _______ _________ _______           _______  _______  _______  _______ 
//  |\     /|( (    /|\__   __/( \      (  ____ \|\     /|(  ____ \(  ____ )  (       )(  ____ \\__   __/(  ___  )|\     /|(  ____ \(  ____ )(  ____ \(  ____ \
//  | )   ( ||  \  ( |   ) (   | (      | (    \/| )   ( || (    \/| (    )|  | () () || (    \/   ) (   | (   ) || )   ( || (    \/| (    )|| (    \/| (    \/
//  | |   | ||   \ | |   | |   | |      | (__    | |   | || (__    | (____)|  | || || || (__       | |   | (___) || |   | || (__    | (____)|| (_____ | (__    
//  | |   | || (\ \) |   | |   | |      |  __)   ( (   ) )|  __)   |     __)  | |(_)| ||  __)      | |   |  ___  |( (   ) )|  __)   |     __)(_____  )|  __)   
//  | |   | || | \   |   | |   | |      | (       \ \_/ / | (      | (\ (     | |   | || (         | |   | (   ) | \ \_/ / | (      | (\ (         ) || (      
//  | (___) || )  \  |___) (___| (____/\| (____/\  \   /  | (____/\| ) \ \__  | )   ( || (____/\   | |   | )   ( |  \   /  | (____/\| ) \ \__/\____) || (____/\
//  (_______)|/    )_)\_______/(_______/(_______/   \_/   (_______/|/   \__/  |/     \|(_______/   )_(   |/     \|   \_/   (_______/|/   \__/\_______)(_______/
//                                                                                                                                                             
//
//                                                                                                                                   
                                                   

pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract UnileverMetaverseToken {

    // Unilever Metaverse Token

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
