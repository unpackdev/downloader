
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BTW
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//           ::::::::: ::::::::::: :::       :::     //
//          :+:    :+:    :+:     :+:       :+:      //
//         +:+    +:+    +:+     +:+       +:+       //
//        +#++:++#+     +#+     +#+  +:+  +#+        //
//       +#+    +#+    +#+     +#+ +#+#+ +#+         //
//      #+#    #+#    #+#      #+#+# #+#+#           //
//     #########     ###       ###   ###             //
//    ### BTW BY HANNESWINDRATH.ETH ###              //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract BTW is ERC721Creator {
    constructor() ERC721Creator("BTW", "BTW") {}
}
