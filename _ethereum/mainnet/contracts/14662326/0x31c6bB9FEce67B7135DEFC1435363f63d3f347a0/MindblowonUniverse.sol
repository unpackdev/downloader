// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//  __       __  __                  __  __        __                                                    __    __            __                                                    
// |  \     /  \|  \                |  \|  \      |  \                                                  |  \  |  \          |  \                                                   
// | $$\   /  $$ \$$ _______    ____| $$| $$____  | $$  ______   __   __   __   ______   _______        | $$  | $$ _______   \$$ __     __   ______    ______    _______   ______  
// | $$$\ /  $$$|  \|       \  /      $$| $$    \ | $$ /      \ |  \ |  \ |  \ /      \ |       \       | $$  | $$|       \ |  \|  \   /  \ /      \  /      \  /       \ /      \ 
// | $$$$\  $$$$| $$| $$$$$$$\|  $$$$$$$| $$$$$$$\| $$|  $$$$$$\| $$ | $$ | $$|  $$$$$$\| $$$$$$$\      | $$  | $$| $$$$$$$\| $$ \$$\ /  $$|  $$$$$$\|  $$$$$$\|  $$$$$$$|  $$$$$$\
// | $$\$$ $$ $$| $$| $$  | $$| $$  | $$| $$  | $$| $$| $$  | $$| $$ | $$ | $$| $$  | $$| $$  | $$      | $$  | $$| $$  | $$| $$  \$$\  $$ | $$    $$| $$   \$$ \$$    \ | $$    $$
// | $$ \$$$| $$| $$| $$  | $$| $$__| $$| $$__/ $$| $$| $$__/ $$| $$_/ $$_/ $$| $$__/ $$| $$  | $$      | $$__/ $$| $$  | $$| $$   \$$ $$  | $$$$$$$$| $$       _\$$$$$$\| $$$$$$$$
// | $$  \$ | $$| $$| $$  | $$ \$$    $$| $$    $$| $$ \$$    $$ \$$   $$   $$ \$$    $$| $$  | $$       \$$    $$| $$  | $$| $$    \$$$    \$$     \| $$      |       $$ \$$     \
//  \$$      \$$ \$$ \$$   \$$  \$$$$$$$ \$$$$$$$  \$$  \$$$$$$   \$$$$$\$$$$   \$$$$$$  \$$   \$$        \$$$$$$  \$$   \$$ \$$     \$      \$$$$$$$ \$$       \$$$$$$$   \$$$$$$$
                                                                                                                                                                                
                                                                                                                                                                                
                                                                                                                                                                                

import "./Address.sol";
import "./StorageSlot.sol";

contract MindblowonUniverse{
   //MindblowonUniverse                                                        
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

