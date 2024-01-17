
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 42 Characters
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccca688888888888888888888bbb2bxccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccx8888b9e88888888888bb888888b998b3bcccccccccccccccccc    //
//    cccccccccccccccccccccccccccf8888b888888888885bbbbbbbbbb8b988b8bccccccccccccccccc    //
//    cccccccccccccccccccccccccc1b9999c8888888888b88888888b988888888cccccccccccccccccc    //
//    cccccccccccccccccccccccccc7b9999b85885775b888888888b88588888bccccccccccccccccccc    //
//    ccccccccccccccccccccccccccc88888bb888bx8988888888b988888888bcccccccccccccccccccc    //
//    ccccccccccccccccccccccccccc78b8888b88bb888888888b888888827cccccccccccccccccccccc    //
//    ccccccccccccccccaaeeaccccccc78888888b99999988889888588bccccccccccccccccccccccccc    //
//    cccccccccccccc1b85558588becccc7888b77c9999999988888b7ccccccccccccccccccccccccccc    //
//    ccccccccccccccc714b9fbf03555eeaabb77777777c998885bcccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccc77778eeb7c7777777778888bcccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccc8bccccccc777a8888b85ccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccab7cccccccccca8888bb888cccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccabccccccccccc8888888888888cccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccc8ccccccccccca8888888888888888cccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccabccccccccccca888858885888888888bcccccccccccccccccccccccc    //
//    cccccccccccccccccccccc1bccccccccccc88888b88888e5888888888bcccccccccccccccccccccc    //
//    ccccccccccccccccccccc4bcccccccccca88888b8b88bb588858888888bccccccccccccccccccccc    //
//    cccccccccccccccccccc6b9ccccccccca888887888b7899958885888888ccccccccccccccccccccc    //
//    ccccccccccccccccccc1b99999ccccc88888bcc7888bc78888b88888885b8888bccccccccccccccc    //
//    cccccccccccccccccccbbb9999999c88888bccccc788888ee22588858899888888cccccccccccccc    //
//    cccccccccccccccccc8bbbbbbb999888888ccccccca255888b99998888888888888ccccccccccccc    //
//    cccccccccccccccccc888888bbbb888888bbb99999988889ff9f888f888888888888cccccccccccc    //
//    cccccccccccccccccc888888888888888bbbb88899999999999888f8888888888827cccccccccccc    //
//    cccccccccccccccccc7888888888888888bbbbff88898898888888888888888f7ccccccccccccccc    //
//    ccccccccccccccccccc388888888888888bbbbb8ff888888899888888877cccccccccccccccccccc    //
//    cccccccccccccccccccc74888888888888888bb888888888888477cccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccc7888888888888888888884577cccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccc7777777777cccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccc WE ARE ALL CHARACTERS cccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract C42 is ERC721Creator {
    constructor() ERC721Creator("42 Characters", "C42") {}
}
