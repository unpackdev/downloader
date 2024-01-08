
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: La+ch
/// @author: manifold.xyz

import "./Proxy.sol";
import "./Address.sol";
import "./StorageSlot.sol";

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//                 ......                                                            //
//                            .;lxkkxxxxkxdl;..                                      //
//                          'dOOo:'.....';coxOOxl;.                                  //
//                        .dKx;.             .':okOxc.                               //
//                      .c0O;                     'ck0d,                             //
//                     'kKo.                         ,xKk,                           //
//                    :KK;  ,olccc:,.    ,xOkdc,.      'dKx,                         //
//                   ;K0,  ;XWWWMMMNXO;  dMMMMMW0o'      ;0Kl.                       //
//                  .OK;  .kMk,:kNMMMMX: cWWkld0WMXo.     .oXk'                      //
//                 'ONl   .OMKl. ,kWMMMx.:NNc  .cKMWd.      :K0;                     //
//                .xMk.    dMMX;  lWMMMk.'0Md.   lWMX;       'OK;                    //
//                :XK;     ;XMNd;oXMMMMO. oWO.   '0MWo        'OK:                   //
//               .xWo    .  :KMWMMMMMNx'  '0Nc   .kMMd         'OK,                  //
//               cNK,    .   .cdkkdc:'     cXK;  .kMMd          ;Xk.                 //
//              ;KMO.                       lNXo;dNMX;           oNc                 //
//             .kMMd                         :KMWWMNo.           ,KO.                //
//             cNMWc                          .oOOx;             .xN:                //
//             ;KMWl                                              cNd                //
//              dMMk.     ,llllllc::::::::::clloddxxxlccoxkd,     ,KO.               //
//             .kMMNl    .oNMKolxNW0ddo0WMMMMKokWMKokWWkkWMK;     .xX;               //
//             .OXdkKc    .xMO. .kWd.  cWMMMM0',KMk..OXclWX;       lWl               //
//             .O0'.lKk'   ,KNc  cN0o' :NMMMMX;.kM0'.xW0KWo        ;Xx.              //
//             ,KO.  'x0d, .kMKl:xWWW0lxNMMMMNl.dMX: lWMMX;       .dNK;              //
//             cWx.    ,d0kooollooolccloxOKXXNKOXWW0k0WMMX;     .;OWMMO.             //
//             dWo       .;oxxo;.         ...'',,,,'',oOx:.   .c0WMMWWN:             //
//            ,KK,           'cdkkdlc:,..                  .lkXWMMMWddNo             //
//           .dWd.              .':lodxxxxxolc::,'.    .;cxXMMN0ocOWl.OK,            //
//           ;XN:                       .';cloddxxxxxxOXWMNKkl,.  cNd.cNo            //
//          .xM0'                                 ..',;;;;'.      ,KO..O0'           //
//          ,KNl                                                  .kX; oNl           //
//         .kWk.                                                   lNo :Xd           //
//        ,0M0'                                                    '0O..OO.          //
//        ,xd'                                                      dN: dNc          //
//                                                                  ;Xd cNk.         //
//                                                                  .k0''0K;         //
//                                                                   cNo.oNo         //
//                                                                   .O0''0K,        //
//                                                                    oWo.oWd        //
//                                                                    ;K0';XX;       //
//                                                                    .dNc.dWk.      //
//                                                                     :NO.'0Nc      //
//                                                                     .kNc.lW0'     //
//                                                                      cNK;.OWo     //
//                                                                      ;XWd.;KO'    //
//                                                                       ',.  ..     //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////


contract LATCH is Proxy {
    
    constructor(address creatorImplementation) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = creatorImplementation;
        Address.functionDelegateCall(
            creatorImplementation,
            abi.encodeWithSignature("initialize(string,string)", "La+ch", "LATCH")
        );
    }
        
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
     function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }    

}
