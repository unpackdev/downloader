
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


                                                                                                                
// o                    o          o     o         o   o    o                      .oo                  .8     .8  
// 8                               8     8             8    8                     .P 8                 d'8    d'8  
// 8     .oPYo. o    o o8 .oPYo.   8     8 o    o o8  o8P  o8P .oPYo. odYo.      .P  8 .oPYo. .oPYo.  d' 8   d' 8  
// 8     8    8 8    8  8 Yb..     `b   d' 8    8  8   8    8  8    8 8' `8     oPooo8 8    8 8oooo8 Pooooo Pooooo 
// 8     8    8 8    8  8   'Yb.    `b d'  8    8  8   8    8  8    8 8   8    .P    8 8    8 8.         8      8  
// 8oooo `YooP' `YooP'  8 `YooP'     `8'   `YooP'  8   8    8  `YooP' 8   8   .P     8 8YooP' `Yooo'     8      8  
// ......:.....::.....::..:.....::::::..::::.....::..::..:::..::.....:..::..::..:::::..8 ....::.....:::::..:::::..:
// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::8 ::::::::::::::::::::::::::
// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::..::::::::::::::::::::::::::
