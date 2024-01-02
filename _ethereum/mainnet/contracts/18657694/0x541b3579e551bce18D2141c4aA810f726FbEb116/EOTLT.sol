// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Edge Of The Lost Tokens
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//                                                                                          //
//     ___                  _        ___                            ___                     //
//     )_  _ ) _     _     / ) _(_    ) ( _   _     )   _   _ _)_    ) _ ( _  _   _   _     //
//    (__ (_( (_(   )_)   (_/    )   (   ) ) )_)   (__ (_) (  (_    ( (_) )\ )_) ) ) (      //
//              _) (_                       (_             _)               (_       _)     //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract EOTLT is ERC1155Creator {
    constructor() ERC1155Creator("Edge Of The Lost Tokens", "EOTLT") {}
}
