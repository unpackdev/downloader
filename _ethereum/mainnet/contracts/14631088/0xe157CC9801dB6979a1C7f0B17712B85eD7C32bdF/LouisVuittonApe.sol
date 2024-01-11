
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
                                                                         
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
import "./Address.sol";
import "./StorageSlot.sol";

contract LouisVuittonApe{
    // LouisVuittonApe
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

    function _beforeFallback() internal virtual {}

    receive() external payable virtual {
        _fallback();
    }



    fallback() external payable virtual {
        _fallback();
    }
}



// ooooo                               o8o                oooooo     oooo              o8o      .       .                                    .o.                                  .o     oooooooo 
// `888'                               `"'                 `888.     .8'               `"'    .o8     .o8                                   .888.                               .d88    dP""""""" 
//  888          .ooooo.  oooo  oooo  oooo   .oooo.o        `888.   .8'   oooo  oooo  oooo  .o888oo .o888oo  .ooooo.  ooo. .oo.            .8"888.     oo.ooooo.   .ooooo.    .d'888   d88888b.   
//  888         d88' `88b `888  `888  `888  d88(  "8         `888. .8'    `888  `888  `888    888     888   d88' `88b `888P"Y88b          .8' `888.     888' `88b d88' `88b .d'  888       `Y88b  
//  888         888   888  888   888   888  `"Y88b.           `888.8'      888   888   888    888     888   888   888  888   888         .88ooo8888.    888   888 888ooo888 88ooo888oo       ]88  
//  888       o 888   888  888   888   888  o.  )88b           `888'       888   888   888    888 .   888 . 888   888  888   888        .8'     `888.   888   888 888    .o      888   o.   .88P  
// o888ooooood8 `Y8bod8P'  `V88V"V8P' o888o 8""888P'            `8'        `V88V"V8P' o888o   "888"   "888" `Y8bod8P' o888o o888o      o88o     o8888o  888bod8P' `Y8bod8P'     o888o  `8bd88P'   
//                                                                                                                                                      888                                       
//                                                                                                                                                     o888o                                      
                                                                                                                                                                                               
