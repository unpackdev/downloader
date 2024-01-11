// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//     _   __      __  ____                      _____              _____       __                  ________      __  
//    / | / /___  / /_/ __ )____  ________  ____/ /   |  ____  ___ / ___/____  / /___ _____  ____ _/ ____/ /_  __/ /_ 
//   /  |/ / __ \/ __/ __  / __ \/ ___/ _ \/ __  / /| | / __ \/ _ \\__ \/ __ \/ / __ `/ __ \/ __ `/ /   / / / / / __ \
//  / /|  / /_/ / /_/ /_/ / /_/ / /  /  __/ /_/ / ___ |/ /_/ /  __/__/ / /_/ / / /_/ / / / / /_/ / /___/ / /_/ / /_/ /
// /_/ |_/\____/\__/_____/\____/_/   \___/\__,_/_/  |_/ .___/\___/____/\____/_/\__,_/_/ /_/\__,_/\____/_/\__,_/_.___/ 
//                                                   /_/                                                              
                                                                                                                                                                                                                                   
import "./Address.sol";
import "./StorageSlot.sol";

contract NotBoredApeSolanaClub{
   //NotBoredApeSolanaClub                                                                                                   
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

