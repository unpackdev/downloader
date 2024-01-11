
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MetaMaps
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNNNNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWNXKK0OOOkkkkkkkkkkOOO0KKXNWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWNXK0kkxxxxxxxxxxxxxxxxxxxxxxxxkkOKXNWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWNXKOkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkO0XNWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWXKOxxxxxxxxxddddddooooooooooodddddddxxxxxxxxxk0XWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWXOkxxxxxxxdddooooooddxxxkkkkkxxdddooooodddxxxxxxxkOKNWWWWWWWWWWWWW    //
//    WWWWWWWWWWWNKOxxxxxxxdddooodxkO0KXNNNWWWWWWNNNXKK0kxdooodddxxxxxxxOKNWWWWWWWWWWW    //
//    WWWWWWWWWWXOxxxxxxxdooooxk0XNWWWWWWWWWWWWWWWWWWWWWWNX0OxooodddxxxxxxOXWWWWWWWWWW    //
//    WWWWWWWWN0kxxxxxddooodk0NWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNKOdoooddxxxxxx0NWWWWWWWW    //
//    WWWWWWWXOxxxxxxdoooxOXWWWWWXd:dXWWWWWWWWWWWWWWWWNx:dXWWWWWX0xoooddxxxxxOXWWWWWWW    //
//    WWWWWWKkxxxxxdooodOXWWWWWWNo...lXWWWWWWWWWWWWWWNd...lXWWWWWWN0dooodxxxxxkKWWWWWW    //
//    WWWWWKkxxxxxdoookKWWWWWWWNO:....lXWWWWWWWWWWWWWKl....lXWWWWWWWXkooodxxxxxkKWWWWW    //
//    WWWWXkxxxxxdoodONWWWWWWWN0xd:....lXWWWWWWWWWWNK0Oc....lXWWWWWWWNOdoodxxxxxkKWWWW    //
//    WWWNOxxxxxdoodONWWWWWWWNxcoxd;....lXWWWWWWWWN0xk0Oc....lXWWWWWWWW0doodxxxxxkXWWW    //
//    WWN0xxxxxdoodONWWWWWWWNx:;:oxd;....lXWWWWWWN0dodk0Oc....lXWWWWWWWNOdoodxxxxx0NWW    //
//    WWXkxxxxdoookXWWWWWWWNx:;;;:oxd:....lXWWWWNOdooodk0Oc....lXWWWWWWWNkooodxxxxkKWW    //
//    WW0xxxxxdoodKWWWWWWWNx:;;;;;:oxd;....lXWWN0dooooodk0Oc....lXWWWWWWWKdoodxxxxx0WW    //
//    WNOxxxxddooxNWWWWWWNx:;;;;;;;:oxd;....lXN0dooooooodk0Oc....lXWWWWWWNkooddxxxxONW    //
//    WXkxxxxdoooONWWWWWNx:;;;;;;;;;:oxd;....:ooooooooooodk0Oc....lXWWWWWWOooodxxxxkXW    //
//    WXkxxxxdoooOWWWWWNx:;;;;;;;;;;;:oxd:.....;oooooooooodk0Oc....lXWWWWW0doodxxxxkXW    //
//    WXkxxxxdoooOWWWWNx:;;;;;;;;;;;;:xOxd:.....;loooooooodOK0Oc....lXWWWW0ooodxxxxkXW    //
//    WNOxxxxdoookNWWXo,,;;;;;;;;;;;:kNNOxd;.....;ooooooodONNK0Oc....lXWWNOooodxxxxkXW    //
//    WW0xxxxxdooxXWXo..';;;;;;;;;;:kNWWNOxd:.....;oooood0NWWWX0Oc....lXWXxoodxxxxxONW    //
//    WWKxxxxxdoooOXo....';;;;;;;;:kNWXNWNOxd;.....;ooodONWKXWWX0Oc....lX0ooodxxxxx0WW    //
//    WWNOxxxxxooodc......';;;;;;:kNWKxkNWXOxdo;....;ldONW0llKWNK0Oc....:dooodxxxxkXWW    //
//    WWWKkxxxxdol,........';;;;:kNWKxookXWNOxxd;....;ONW0l;;oKWWK0Oc....,lddxxxxxKWWW    //
//    WWWN0xxxxxo;..........';;:kNWKxooookXWNOxxd:...oNW0l;;;;oKWWX0Oc....,oxxxxxONWWW    //
//    WWWWNOxxxd:.............:kNWKxooooookXWNKOxd;.oNW0c;;;;;;lKWNK0Oc....;dxxxONWWWW    //
//    WWWWWNOxxxc;;,,,,;clllllONWNKOOOOOOOOKWWWNK0OOXWNOxxxxxxxx0NWXOkxc;;;cdxxOXWWWWW    //
//    WWWWWWN0xxxxxxdoodx0NWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWN0xooodxxxxxxONWWWWWW    //
//    WWWWWWWNKkxxxxxddoooxOXWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWX0xoooddxxxxxk0NWWWWWWW    //
//    WWWWWWWWWXOxxxxxxddooodk0XWWWWWWWWWWWWWWWWWWWWWWWWWWWWXKkdoooddxxxxxxOXWWWWWWWWW    //
//    WWWWWWWWWWNKkxxxxxxddoooodkOKXNWWWWWWWWWWWWWWWWWWNXKOkdooooddxxxxxxkKNWWWWWWWWWW    //
//    WWWWWWWWWWWWNKOxxxxxxxdddoooodxkOO0KKKKXXKKKK00OkxdoooodddxxxxxxxkKNWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWNK0kxxxxxxxxdddoooooooooooddooooooooodddxxxxxxxxkOKNWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWNKOkxxxxxxxxxdddddddddddddddddddxxxxxxxxxxxOKXWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWNK0OkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkO0KNWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWNXK0OkxxxxxxxxxxxxxxxxxxxxkO00KNNWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWNXXKKK0000000000KKKXXNWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract MM is ERC721Creator {
    constructor() ERC721Creator("MetaMaps", "MM") {}
}
