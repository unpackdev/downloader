// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FlyZ Burn
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////
//                          //
//                          //
//            __            //
//       -. (#)(#) .-       //
//        '\.';;'./'        //
//     .-\.'  ;;  './-.     //
//       ;    ;;    ;       //
//       ;   .''.   ;       //
//        '''    '''        //
//                          //
//                          //
//////////////////////////////


contract FLBU is ERC1155Creator {
    constructor() ERC1155Creator("FlyZ Burn", "FLBU") {}
}
