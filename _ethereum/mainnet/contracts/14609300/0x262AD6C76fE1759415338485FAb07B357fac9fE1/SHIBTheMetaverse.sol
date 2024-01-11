
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
                                                                         
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
import "./Address.sol";
import "./StorageSlot.sol";

contract SHIBTheMetaverse {
    // SHIB The Metaverse
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

//                                                                                                                            _____                                    _____                                                                 _____                                              _____   
//             _____       __     __         ____________ ______  ______    ________    ________      __     __          _____\    \        ___________           _____\    \   ________    ________      _____     _______    ______   _____\    \ ___________                  _____     _____\    \  
//        _____\    \     /  \   /  \       /            \\     \|\     \  /        \  /        \    /  \   /  \        /    / |    |      /           \         /    / |    | /        \  /        \   /      |_   \      |  |      | /    / |    |\          \            _____\    \   /    / |    | 
//       /    / \    |   /   /| |\   \     |\___/\  \\___/||     |\|     ||\         \/         /|  /   /| |\   \      /    /  /___/|     /    _   _    \       /    /  /___/||\         \/         /| /         \   |     /  /     /|/    /  /___/| \    /\    \          /    / \    | /    /  /___/| 
//      |    |  /___/|  /   //   \\   \     \|____\  \___|/|     |/____ / | \            /\____/ | /   //   \\   \    |    |__ |___|/    /    //   \\    \     |    |__ |___|/| \            /\____/ ||     /\    \  |\    \  \    |/|    |__ |___|/  |   \_\    |        |    |  /___/||    |__ |___|/ 
//   ____\    \ |   || /    \_____/    \          |  |     |     |\     \ |  \______/\   \     | |/    \_____/    \   |       \         /    //     \\    \    |       \      |  \______/\   \     | ||    |  |    \ \ \    \ |    | |       \        |      ___/      ____\    \ |   |||       \       
//  /    /\    \|___|//    /\_____/\    \    __  /   / __  |     | |     | \ |      | \   \____|//    /\_____/\    \  |     __/ __     /     \\_____//     \   |     __/ __    \ |      | \   \____|/ |     \/      \ \|     \|    | |     __/ __     |      \  ____  /    /\    \|___|/|     __/ __    
// |    |/ \    \    /    //\_____/\\    \  /  \/   /_/  | |     | |     |  \|______|  \   \    /    //\_____/\\    \ |\    \  /  \   /       \ ___ /       \  |\    \  /  \    \|______|  \   \      |\      /\     \ |\         /| |\    \  /  \   /     /\ \/    \|    |/ \    \     |\    \  /  \   
// |\____\ /____/|  /____/ |       | \____\|____________/|/_____/|/_____/|           \  \___\  /____/ |       | \____\| \____\/    | /________/|   |\________\ | \____\/    |            \  \___\     | \_____\ \_____\| \_______/ | | \____\/    | /_____/ |\______||\____\ /____/|    | \____\/    |  
// | |   ||    | |  |    | |       | |    ||           | /|    |||     | |            \ |   |  |    | |       | |    || |    |____/||        | |   | |        || |    |____/|             \ |   |     | |     | |     | \ |     | /  | |    |____/| |     | | |     || |   ||    | |    | |    |____/|  
//  \|___||____|/   |____|/         \|____||___________|/ |____|/|_____|/              \|___|  |____|/         \|____| \|____|   | ||________|/     \|________| \|____|   | |              \|___|      \|_____|\|_____|  \|_____|/    \|____|   | | |_____|/ \|_____| \|___||____|/      \|____|   | |  
//                                                                                                                           |___|/                                   |___|/                                                                |___|/                                             |___|/   

    function _beforeFallback() internal virtual {}


    receive() external payable virtual {
        _fallback();
    }

                                                                                                                                                                                                                                                            

    fallback() external payable virtual {
        _fallback();
    }
}

