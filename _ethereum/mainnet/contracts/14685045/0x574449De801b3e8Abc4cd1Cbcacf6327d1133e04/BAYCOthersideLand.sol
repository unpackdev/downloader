
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

                                                                    
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
import "./Address.sol";
import "./StorageSlot.sol";

contract BAYCOthersideLand{
    // BAYC Otherside Land                                                                                                          
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

                                                                                


// M#"""""""'M  MMP"""""""MM M""MMMM""M MM'""""'YMM MMP"""""YMM   dP   dP                                  oo       dP          M""MMMMMMMM                         dP d88  dP   dP 
// ##  mmmm. `M M' .mmmm  MM M. `MM' .M M' .mmm. `M M' .mmm. `M   88   88                                           88          M  MMMMMMMM                         88  88  88   88 
// #'        .M M         `M MM.    .MM M  MMMMMooM M  MMMMM  M d8888P 88d888b. .d8888b. 88d888b. .d8888b. dP .d888b88 .d8888b. M  MMMMMMMM .d8888b. 88d888b. .d888b88  88  88aaa88 
// M#  MMMb.'YM M  MMMMM  MM MMMb  dMMM M  MMMMMMMM M  MMMMM  M   88   88'  `88 88ooood8 88'  `88 Y8ooooo. 88 88'  `88 88ooood8 M  MMMMMMMM 88'  `88 88'  `88 88'  `88  88       88 
// M#  MMMM'  M M  MMMMM  MM MMMM  MMMM M. `MMM' .M M. `MMM' .M   88   88    88 88.  ... 88             88 88 88.  .88 88.  ... M  MMMMMMMM 88.  .88 88    88 88.  .88  88       88 
// M#       .;M M  MMMMM  MM MMMM  MMMM MM.     .dM MMb     dMM   dP   dP    dP `88888P' dP       `88888P' dP `88888P8 `88888P' M         M `88888P8 dP    dP `88888P8 d88P      dP 
// M#########M  MMMMMMMMMMMM MMMMMMMMMM MMMMMMMMMMM MMMMMMMMMMM                                                                 MMMMMMMMMMM                                         
                                                                                                                                                                                 
                                                          
                                                                                                      
    
                                                                                                                                                                                                            

    fallback() external payable virtual {
        _fallback();
    }
}



