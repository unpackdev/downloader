// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 𝐄𝐃𝐈𝐓𝐈𝐎𝐍'𝐬 𝐛𝐲 𝐂𝐀𝐋𝐋𝐀𝐕𝐄𝐑𝐎𝐍
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//    𝐄𝐃𝐈𝐓𝐈𝐎𝐍'𝐬 𝐛𝐲 𝐂𝐀𝐋𝐋𝐀𝐕𝐄𝐑𝐎𝐍    //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract EBYC is ERC1155Creator {
    constructor() ERC1155Creator(unicode"𝐄𝐃𝐈𝐓𝐈𝐎𝐍'𝐬 𝐛𝐲 𝐂𝐀𝐋𝐋𝐀𝐕𝐄𝐑𝐎𝐍", "EBYC") {}
}
