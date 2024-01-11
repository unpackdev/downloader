/**
██╗   ██╗███╗   ██╗██╗███╗   ███╗██╗███╗   ██╗████████╗
██║   ██║████╗  ██║██║████╗ ████║██║████╗  ██║╚══██╔══╝
██║   ██║██╔██╗ ██║██║██╔████╔██║██║██╔██╗ ██║   ██║   
██║   ██║██║╚██╗██║██║██║╚██╔╝██║██║██║╚██╗██║   ██║   
╚██████╔╝██║ ╚████║██║██║ ╚═╝ ██║██║██║ ╚████║   ██║   
 ╚═════╝ ╚═╝  ╚═══╝╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝   

 ______   ______   ______  _______  ______   ______  ______   _       
| |  | \ | |  | \ / |  | \   | |   / |  | \ | |     / |  | \ | |      
| |__|_/ | |__| | | |  | |   | |   | |  | | | |     | |  | | | |   _  
|_|      |_|  \_\ \_|__|_/   |_|   \_|__|_/ |_|____ \_|__|_/ |_|__|_| 
                                                                                       
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title: ERC721Mini
/// @author: unimint.org

import "./Proxy.sol";
import "./Address.sol";
import "./StorageSlot.sol";

import "./ERC721BatchMintConfig.sol";

contract ERC721Mini is Proxy {
    constructor(string memory name, string memory symbol) {
        assert(
            _IMPLEMENTATION_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
        );
        StorageSlot
            .getAddressSlot(_IMPLEMENTATION_SLOT)
            .value = ERC721BatchMintConfig.ADDRESS;
        Address.functionDelegateCall(
            ERC721BatchMintConfig.ADDRESS,
            abi.encodeWithSignature("initialize(string,string)", name, symbol)
        );
    }

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal view override returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }
}
