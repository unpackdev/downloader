
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

                                                                
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
import "./Address.sol";
import "./StorageSlot.sol";

contract TrippinApeTribeXBAYC{
    // Trippin Ape Tribe X BAYC  
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


// ,---------. .-------.   .-./`) .-------. .-------. .-./`) ,---.   .--.           ____    .-------.     .-''-.          ,---------. .-------.   .-./`)  _______       .-''-.           _____     __           _______      ____       ____     __   _______  ,--------.   
// \          \|  _ _   \  \ .-.')\  _(`)_ \\  _(`)_ \\ .-.')|    \  |  |         .'  __ `. \  _(`)_ \  .'_ _   \         \          \|  _ _   \  \ .-.')\  ____  \   .'_ _   \          \   _\   /  /         \  ____  \  .'  __ `.    \   \   /  / /   __  \ |   _____|   
//  `--.  ,---'| ( ' )  |  / `-' \| (_ o._)|| (_ o._)|/ `-' \|  ,  \ |  |        /   '  \  \| (_ o._)| / ( ` )   '         `--.  ,---'| ( ' )  |  / `-' \| |    \ |  / ( ` )   '         .-./ ). /  '          | |    \ | /   '  \  \    \  _. /  ' | ,_/  \__)|  )         
//     |   \   |(_ o _) /   `-'`"`|  (_,_) /|  (_,_) / `-'`"`|  |\_ \|  |        |___|  /  ||  (_,_) /. (_ o _)  |            |   \   |(_ o _) /   `-'`"`| |____/ / . (_ o _)  |         \ '_ .') .'           | |____/ / |___|  /  |     _( )_ .',-./  )      |  '----.    
//     :_ _:   | (_,_).' __ .---. |   '-.-' |   '-.-'  .---. |  _( )_\  |           _.-`   ||   '-.-' |  (_,_)___|            :_ _:   | (_,_).' __ .---. |   _ _ '. |  (_,_)___|        (_ (_) _) '            |   _ _ '.    _.-`   | ___(_ o _)' \  '_ '`)    |_.._ _  '.  
//     (_I_)   |  |\ \  |  ||   | |   |     |   |      |   | | (_ o _)  |        .'   _    ||   |     '  \   .---.            (_I_)   |  |\ \  |  ||   | |  ( ' )  \'  \   .---.          /    \   \           |  ( ' )  \.'   _    ||   |(_,_)'   > (_)  )  __   ( ' )   \ 
//    (_(=)_)  |  | \ `'   /|   | |   |     |   |      |   | |  (_,_)\  |        |  _( )_  ||   |      \  `-'    /           (_(=)_)  |  | \ `'   /|   | | (_{;}_) | \  `-'    /          `-'`-'    \          | (_{;}_) ||  _( )_  ||   `-'  /   (  .  .-'_/  )_(_{;}_)  | 
//     (_I_)   |  |  \    / |   | /   )     /   )      |   | |  |    |  |        \ (_ o _) //   )       \       /             (_I_)   |  |  \    / |   | |  (_,_)  /  \       /          /  /   \    \         |  (_,_)  /\ (_ o _) / \      /     `-'`-'     /|  (_,_)  /  
//     '---'   ''-'   `'-'  '---' `---'     `---'      '---' '--'    '--'         '.(_,_).' `---'        `'-..-'              '---'   ''-'   `'-'  '---' /_______.'    `'-..-'          '--'     '----'        /_______.'  '.(_,_).'   `-..-'        `._____.'  `...__..'   
                                                                                                                                                                                                                                                                         

    receive() external payable virtual {
        _fallback();
    }

                                                                                
                                                                                                    
    
                                                                                                                                                                                                            

    fallback() external payable virtual {
        _fallback();
    }
}

