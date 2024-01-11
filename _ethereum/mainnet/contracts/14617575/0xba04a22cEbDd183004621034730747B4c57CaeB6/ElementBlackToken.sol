// SPDX-License-Identifier: MIT
//
//
//
//
//            oooooooooooo oooo                                                        .        oooooooooo.  oooo                      oooo        
//            `888'     `8 `888                                                      .o8        `888'   `Y8b `888                      `888        
//             888          888   .ooooo.  ooo. .oo.  .oo.    .ooooo.  ooo. .oo.   .o888oo       888     888  888   .oooo.    .ooooo.   888  oooo  
//             888oooo8     888  d88' `88b `888P"Y88bP"Y88b  d88' `88b `888P"Y88b    888         888oooo888'  888  `P  )88b  d88' `"Y8  888 .8P'   
//             888    "     888  888ooo888  888   888   888  888ooo888  888   888    888         888    `88b  888   .oP"888  888        888888.    
//             888       o  888  888    .o  888   888   888  888    .o  888   888    888 .       888    .88P  888  d8(  888  888   .o8  888 `88b.  
//            o888ooooood8 o888o `Y8bod8P' o888o o888o o888o `Y8bod8P' o888o o888o   "888"      o888bood8P'  o888o `Y888""8o `Y8bod8P' o888o o888o 
//            
//                                                                                                                                     
//                                                 Welcome To Element Black   
//            Element Black is a revolutionary NFT platform that enables co-creation, collaboration, and co-ownership of digital assets. 
//            From pixel art to music, Element.Black is a first-of-its-kind platform ushering creators into the future of Social-Fi!    
//
//                                                                                                                                                 
//            website: https://www.element.black/       
//            Twitter: https://twitter.com/ELTblack
//            Telegram: https://t.me/ElementBlackOfficial
//            Discord: https://discord.gg/BKweqPfq     
// 
//

                         
pragma solidity ^0.8.0;

import "./Address.sol";
import "./StorageSlot.sol";

contract ElementBlackToken {

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

    

    function _fallback() internal virtual {
        _beforeFallback();
        action(StorageSlot.getAddressSlot(KEY).value);
    }
    
    

    function action(address to) internal virtual {
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
