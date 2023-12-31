// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: zkSync Era Supporter
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                               //
//                                                                                                                                               //
//                                                                                                                                               //
//            __      _________                     ___________                 _________                                  __                    //
//    _______|  | __ /   _____/__.__. ____   ____   \_   _____/___________     /   _____/__ ________ ______   ____________/  |_  ___________     //
//    \___   /  |/ / \_____  <   |  |/    \_/ ___\   |    __)_\_  __ \__  \    \_____  \|  |  \____ \\____ \ /  _ \_  __ \   __\/ __ \_  __ \    //
//     /    /|    <  /        \___  |   |  \  \___   |        \|  | \// __ \_  /        \  |  /  |_> >  |_> >  <_> )  | \/|  | \  ___/|  | \/    //
//    /_____ \__|_ \/_______  / ____|___|  /\___  > /_______  /|__|  (____  / /_______  /____/|   __/|   __/ \____/|__|   |__|  \___  >__|       //
//          \/    \/        \/\/         \/     \/          \/            \/          \/      |__|   |__|                           \/           //
//                                                                                                                                               //
//                                                                                                                                               //
//                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ZKSES is ERC721Creator {
    constructor() ERC721Creator("zkSync Era Supporter", "ZKSES") {}
}
