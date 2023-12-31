// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HodlGums
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                  .............                                                                             //
//                                             .+##*=::::::=+*#*..                                            //
//                                          :*#=:-+*+=-----=+=-:-**-                                          //
//                                       .-#+:=*-:-+*+====++=-::==:-#=.                                       //
//                                      :#+:++:=+-:-+*++++*+-::==:-+--#-                                      //
//                                    .=#:=+:*=:+*-:-******=::=+::+:-+:**.                                    //
//                                    =#:*-=+.+=:*+::=****+:.=+::+:-+:*:+*                                    //
//                                   =#:*:==-*:+=:++::++++-:-*--+:=-:+:*:*+.                                  //
//                                  .*=+==+:+:+:=+:+=:-===:-*--+.+:==-+-*:#:                                  //
//                                  -#:*:*:*-+-+=-+.+=:--:-+:=+-*:*:*:+:+:=+                                  //
//                                  *+:+:+:+:*:*:*:*:+=:::*:*-+-+===-=-=-=-#                                  //
//                                  *=-=-=-+-+-+-*-*-*-**==+==-=-=-=:=:=:+:%.                                 //
//                                  *+:+:+:*:*:*:*:*:++::=*:*-*-+-====-=-=-#                                  //
//                                  -#:*:*:*-+-==:+.++::::=*:==-*:*:*:*:+:++                                  //
//                                  .*==+-+:+:+-=+:++-:-=::=+-=+.+:+==+-+:#:                                  //
//                                   =#:+-=+:*:++.+*::-++=::+*:=*:*=-+:*:**.                                  //
//                                    =#:+=-*.++.+*-.:+**+-..+*:=*.++:*:+*                                    //
//                                    .=#--*:++:=*=.:=****+-:-++:=*:=+:**.                                    //
//                                      :#*:++:-*=:-=+*****=-:=+=:=+:=#-                                      //
//                                        -#*:-*=:-=+*++++*+=-:-*=:=#+.                                       //
//                                          :*#+::=+*+====+*++-:=**-                                          //
//                                             .+##**=-::-=+*##*..                                            //
//                                                ....::::....                                                //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HG is ERC721Creator {
    constructor() ERC721Creator("HodlGums", "HG") {}
}
