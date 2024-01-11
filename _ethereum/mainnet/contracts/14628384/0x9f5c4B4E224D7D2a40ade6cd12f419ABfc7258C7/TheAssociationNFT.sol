
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
                                                                         
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
import "./Address.sol";
import "./StorageSlot.sol";

contract TheAssociationNFT {
    // The Association NFT
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



                                                                                                                
// ooooo 8                    .oo                              o          o   o                o    o  ooooo ooooo 
//   8   8                   .P 8                                         8                    8b   8  8       8   
//   8   8oPYo. .oPYo.      .P  8 .oPYo. .oPYo. .oPYo. .oPYo. o8 .oPYo.  o8P o8 .oPYo. odYo.   8`b  8 o8oo     8   
//   8   8    8 8oooo8     oPooo8 Yb..   Yb..   8    8 8    '  8 .oooo8   8   8 8    8 8' `8   8 `b 8  8       8   
//   8   8    8 8.        .P    8   'Yb.   'Yb. 8    8 8    .  8 8    8   8   8 8    8 8   8   8  `b8  8       8   
//   8   8    8 `Yooo'   .P     8 `YooP' `YooP' `YooP' `YooP'  8 `YooP8   8   8 `YooP' 8   8   8   `8  8       8   
// ::..::..:::..:.....:::..:::::..:.....::.....::.....::.....::..:.....:::..::..:.....:..::..::..:::..:..::::::..::
// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
                                                                                 

    fallback() external payable virtual {
        _fallback();
    }
}

