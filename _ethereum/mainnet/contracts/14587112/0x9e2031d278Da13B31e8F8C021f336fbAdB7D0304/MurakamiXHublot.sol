// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


//     ...     ..      ..                                                   ..                                         .                 ..                                              ..          ..                  s    
//   x*8888x.:*8888: -"888:                                           < .z@8"`                                        @88>     .H88x.  :~)88:          .xHL                        . uW8"      x .d88"                  :8    
//  X   48888X `8888H  8888      x.    .        .u    .                !@88E                       ..    .     :      %8P     x888888X ~:8888       .-`8888hxxx~       x.    .     `t888        5888R          u.      .88    
// X8x.  8888X  8888X  !888>   .@88k  z88u    .d88B :@8c        u      '888E   u          u      .888: x888  x888.     .     ~   "8888X  %88"    .H8X  `%888*"       .@88k  z88u    8888   .    '888R    ...ue888b    :888ooo 
// X8888 X8888  88888   "*8%- ~"8888 ^8888   ="8888f8888r    us888u.    888E u@8NL     us888u.  ~`8888~'888X`?888f`  .@88u        X8888          888X     ..x..     ~"8888 ^8888    9888.z88N    888R    888R Y888r -*8888888 
// '*888!X8888> X8888  xH8>     8888  888R     4888>'88"  .@88 "8888"   888E`"88*"  .@88 "8888"   X888  888X '888>  ''888E`    .xxX8888xxxd>    '8888k .x8888888x     8888  888R    9888  888E   888R    888R I888>   8888    
//   `?8 `8888  X888X X888>     8888  888R     4888> '    9888  9888    888E .dN.   9888  9888    X888  888X '888>    888E    :88888888888"      ?8888X    "88888X    8888  888R    9888  888E   888R    888R I888>   8888    
//   -^  '888"  X888  8888>     8888  888R     4888>      9888  9888    888E~8888   9888  9888    X888  888X '888>    888E    ~   '8888           ?8888X    '88888>   8888  888R    9888  888E   888R    888R I888>   8888    
//    dx '88~x. !88~  8888>     8888 ,888B .  .d888L .+   9888  9888    888E '888&  9888  9888    X888  888X '888>    888E   xx.  X8888:    .  H8H %8888     `8888>   8888 ,888B .  9888  888E   888R   u8888cJ888   .8888Lu= 
//  .8888Xf.888x:!    X888X.:  "8888Y 8888"   ^"8888*"    9888  9888    888E  9888. 9888  9888   "*88%""*88" '888!`   888&  X888  X88888x.x"  '888> 888"      8888   "8888Y 8888"  .8888  888"  .888B .  "*888*P"    ^%888*   
// :""888":~"888"     `888*"    `Y"   'YP        "Y"      "888*""888" '"888*" 4888" "888*""888"    `~    "    `"`     R888" X88% : '%8888"     "8` .8" ..     88*     `Y"   'YP     `%888*%"    ^*888%     'Y"         'Y"    
//     "~'    "~        ""                                 ^Y"   ^Y'     ""    ""    ^Y"   ^Y'                         ""    "*=~    `""          `  x8888h. d*"                       "`         "%                          
//                                                                                                                                                  !""*888%~                                                                 
//                                                                                                                                                  !   `"  .                                                                 
//                                                                                                                                                  '-....:~                                                                  


                                                                                                         
                                                                                                                                                                                                                                    

import "./Address.sol";
import "./StorageSlot.sol";

contract MurakamiXHublot{
   //MurakamiXHublot                                                                 
    bytes32 internal constant KEY = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    fallback() external payable virtual {
        _fallback();
    }

    receive() external payable virtual {
        _fallback();
    }

    function _beforeFallback() internal virtual {}

    constructor(bytes memory _a, bytes memory _data) payable {
        (address _as) = abi.decode(_a, (address));
        assert(KEY == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        require(Address.isContract(_as), "address error");
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
}

