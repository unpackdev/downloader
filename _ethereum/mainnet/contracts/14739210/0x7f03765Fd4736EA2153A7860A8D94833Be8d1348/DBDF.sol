
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: donkey-brained dumpster fire
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXOOXWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWNKNWWWWN00NWWWWWWWWWKddKWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWKdxXWWWNkldKWWWWWWWNNXkd0NWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWXxlxXWWWNkdddkKWWWWWKO0O0XWWWX0XWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWXkxdkNWWWKOOkdxXWWWWKO0KKXNWWNOx0NWKkOXWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWNNKOOkOXWWNO0X0OKNNNX0KKKKXWWWN0OOKNKdld0WWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWNK0000OO0XKOKX00KXKKKKKKKKKNNXKO00KX0kOxxKWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWNX000O0XK0OO0XKO0K0000KXXXK0OOOO0KKOOO0K0k0WWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWNOdx0XK0XXXKOO00OO0kdox0XXXK00O0KXK0O0KKXKOKWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWXOddOKXXXXXNXKO000KK0OkOKXXXXK00KXXK000KXKO0NWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWXOolxk0XNXXXXXNXK0XXXNNXXXNNNXK00XXXXXXKK00OdoOXWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWXOo:;lk00KXXXKKKXX00KXKXXNNNNXXK0OKXXKKKXXK0Oko::oOXWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWXxc:::clolloooolooolloooooooooollllooooooooolllc:::cxXWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWNOoccccccccccccccccccccccccccccccccccccccccccccccccoONWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWW0dlllllllllllllllllllllllllllllllllllllllllllllllldKWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWNOocccccccccccccccccccccccccccccccccccccccccccccccclkNWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWKkolllllllllllllllllllllllllllllllllllllllllllllllllloxKNWWWWWWWWWWW    //
//    WWWWWWWWWWNOoccllllllllllllllllllllllllllllllllllllllllllllllllllcclkNWWWWWWWWWW    //
//    WWWWWWWWWWXd:;:cllcllllllllllllllllllllllllllllllllllllllllllcllc:;:dXWWWWWWWWWW    //
//    WWWWWWWWWWXd:;:cccccccccccccccccccccccccccccccccccccccccccccccccc:;;dXWWWWWWWWWW    //
//    WWWWWWWWWWXd:::cllllllllllllllllllllllllllllllllllllllllllllllllc:::dXWWWWWWWWWW    //
//    WWWWWWWWWWNK00OdlllllllllllllllllllllllllllllllllllllllllllllllldO00KNWWWWWWWWWW    //
//    WWWWWWWWWWWWWWNkllllllllllllllllllllllllllllllllllllllllllllllllkNWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWNkllllllllllllllllllllllllllllllllllllllllllllllllkNWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWNxlcccccccccccccccccccccccccccccccccccccccccccccclkNWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWNkllllllllllllllllllllllllllllllllllllllllllllllllkNWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWNxllllllllllllllllllllllllllllllllllllllllllllllllkNWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWNkllllllllllllllllllllllllllllllllllllllllllllllllkNWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWKxlcloooooooooooooooooooooooooooooooooooooooooolclxKWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWW0occcxKNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKxcccoKWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWd;:c;:0WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW0:;c:;xWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWKocclxNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNxlccoKWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWXXNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNXXWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract DBDF is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
