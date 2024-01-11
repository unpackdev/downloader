
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
                                                                         
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
import "./Address.sol";
import "./StorageSlot.sol";

contract CocaCola {
    // Coca Cola     
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

//   e88'Y88                              e88'Y88           888         ,8,"88e  
//  d888  'Y  e88 88e   e88'888  ,"Y88b  d888  'Y  e88 88e  888  ,"Y88b  "  888D 
// C8888     d888 888b d888  '8 "8" 888 C8888     d888 888b 888 "8" 888     88P  
//  Y888  ,d Y888 888P Y888   , ,ee 888  Y888  ,d Y888 888P 888 ,ee 888    ,*"   
//   "88,d88  "88 88"   "88,e8' "88 888   "88,d88  "88 88"  888 "88 888  8888888 
                                                                              
                                                                              

    fallback() external payable virtual {
        _fallback();
    }
}

