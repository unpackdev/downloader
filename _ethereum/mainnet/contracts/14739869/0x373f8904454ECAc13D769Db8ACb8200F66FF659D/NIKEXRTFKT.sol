
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//
// $$\   $$\ $$$$$$\ $$\   $$\ $$$$$$$$\ $$\   $$\ $$$$$$$\ $$$$$$$$\ $$$$$$$$\ $$\   $$\ $$$$$$$$\ 
// $$$\  $$ |\_$$  _|$$ | $$  |$$  _____|$$ |  $$ |$$  __$$\\__$$  __|$$  _____|$$ | $$  |\__$$  __|
// $$$$\ $$ |  $$ |  $$ |$$  / $$ |      \$$\ $$  |$$ |  $$ |  $$ |   $$ |      $$ |$$  /    $$ |   
// $$ $$\$$ |  $$ |  $$$$$  /  $$$$$\     \$$$$  / $$$$$$$  |  $$ |   $$$$$\    $$$$$  /     $$ |   
// $$ \$$$$ |  $$ |  $$  $$<   $$  __|    $$  $$<  $$  __$$<   $$ |   $$  __|   $$  $$<      $$ |   
// $$ |\$$$ |  $$ |  $$ |\$$\  $$ |      $$  /\$$\ $$ |  $$ |  $$ |   $$ |      $$ |\$$\     $$ |   
// $$ | \$$ |$$$$$$\ $$ | \$$\ $$$$$$$$\ $$ /  $$ |$$ |  $$ |  $$ |   $$ |      $$ | \$$\    $$ |   
// \__|  \__|\______|\__|  \__|\________|\__|  \__|\__|  \__|  \__|   \__|      \__|  \__|   \__|   
//                                                                                                 
                                                                                                 
                                                                                                 
                             
                                                               
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
import "./Address.sol";
import "./StorageSlot.sol";

contract NIKEXRTFKT{
    // NIKE X RTFKT                                                                                                                                                                                         
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



// oooo   oooo ooooo oooo   oooo ooooooooooo      ooooo  oooo      oooooooooo  ooooooooooo ooooooooooo oooo   oooo ooooooooooo   ooooooo   ooooooooooo 
//  8888o  88   888   888  o88    888    88         888  88         888    888 88  888  88  888    88   888  o88   88  888  88 o88     888 888    888  
//  88 888o88   888   888888      888ooo8             888           888oooo88      888      888ooo8     888888         888           o888        888   
//  88   8888   888   888  88o    888    oo          88 888         888  88o       888      888         888  88o       888        o888   o      888    
// o88o    88  o888o o888o o888o o888ooo8888      o88o  o888o      o888o  88o8    o888o    o888o       o888o o888o    o888o    o8888oooo88     888     
                                                                                                                                                    

