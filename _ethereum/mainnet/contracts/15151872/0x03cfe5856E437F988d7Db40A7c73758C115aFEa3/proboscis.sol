
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: proboscisfamily
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                         //
//                                                                                                                                                                         //
//                                                                                                                                                                         //
//                                                             bbbbbbbb                                                                                                    //
//                                                             b::::::b                                                                    iiii                            //
//                                                             b::::::b                                                                   i::::i                           //
//                                                             b::::::b                                                                    iiii                            //
//                                                              b:::::b                                                                                                    //
//    ppppp   ppppppppp   rrrrr   rrrrrrrrr      ooooooooooo    b:::::bbbbbbbbb       ooooooooooo       ssssssssss       cccccccccccccccciiiiiii     ssssssssss            //
//    p::::ppp:::::::::p  r::::rrr:::::::::r   oo:::::::::::oo  b::::::::::::::bb   oo:::::::::::oo   ss::::::::::s    cc:::::::::::::::ci:::::i   ss::::::::::s           //
//    p:::::::::::::::::p r:::::::::::::::::r o:::::::::::::::o b::::::::::::::::b o:::::::::::::::oss:::::::::::::s  c:::::::::::::::::c i::::i ss:::::::::::::s          //
//    pp::::::ppppp::::::prr::::::rrrrr::::::ro:::::ooooo:::::o b:::::bbbbb:::::::bo:::::ooooo:::::os::::::ssss:::::sc:::::::cccccc:::::c i::::i s::::::ssss:::::s         //
//     p:::::p     p:::::p r:::::r     r:::::ro::::o     o::::o b:::::b    b::::::bo::::o     o::::o s:::::s  ssssss c::::::c     ccccccc i::::i  s:::::s  ssssss          //
//     p:::::p     p:::::p r:::::r     rrrrrrro::::o     o::::o b:::::b     b:::::bo::::o     o::::o   s::::::s      c:::::c              i::::i    s::::::s               //
//     p:::::p     p:::::p r:::::r            o::::o     o::::o b:::::b     b:::::bo::::o     o::::o      s::::::s   c:::::c              i::::i       s::::::s            //
//     p:::::p    p::::::p r:::::r            o::::o     o::::o b:::::b     b:::::bo::::o     o::::ossssss   s:::::s c::::::c     ccccccc i::::i ssssss   s:::::s          //
//     p:::::ppppp:::::::p r:::::r            o:::::ooooo:::::o b:::::bbbbbb::::::bo:::::ooooo:::::os:::::ssss::::::sc:::::::cccccc:::::ci::::::is:::::ssss::::::s         //
//     p::::::::::::::::p  r:::::r            o:::::::::::::::o b::::::::::::::::b o:::::::::::::::os::::::::::::::s  c:::::::::::::::::ci::::::is::::::::::::::s          //
//     p::::::::::::::pp   r:::::r             oo:::::::::::oo  b:::::::::::::::b   oo:::::::::::oo  s:::::::::::ss    cc:::::::::::::::ci::::::i s:::::::::::ss           //
//     p::::::pppppppp     rrrrrrr               ooooooooooo    bbbbbbbbbbbbbbbb      ooooooooooo     sssssssssss        cccccccccccccccciiiiiiii  sssssssssss             //
//     p:::::p                                                                                                                                                             //
//     p:::::p                                                                                                                                                             //
//    p:::::::p                                                       kkkkkkkk                                                                                             //
//    p:::::::p                                                       k::::::k                                                                                             //
//    p:::::::p                                                       k::::::k                                                                                             //
//    ppppppppp                                                       k::::::k                                                                                             //
//            mmmmmmm    mmmmmmm      ooooooooooo   nnnn  nnnnnnnn     k:::::k    kkkkkkk    eeeeeeeeeeee    yyyyyyy           yyyyyyy                                     //
//          mm:::::::m  m:::::::mm  oo:::::::::::oo n:::nn::::::::nn   k:::::k   k:::::k   ee::::::::::::ee   y:::::y         y:::::y                                      //
//         m::::::::::mm::::::::::mo:::::::::::::::on::::::::::::::nn  k:::::k  k:::::k   e::::::eeeee:::::ee  y:::::y       y:::::y                                       //
//         m::::::::::::::::::::::mo:::::ooooo:::::onn:::::::::::::::n k:::::k k:::::k   e::::::e     e:::::e   y:::::y     y:::::y                                        //
//         m:::::mmm::::::mmm:::::mo::::o     o::::o  n:::::nnnn:::::n k::::::k:::::k    e:::::::eeeee::::::e    y:::::y   y:::::y                                         //
//         m::::m   m::::m   m::::mo::::o     o::::o  n::::n    n::::n k:::::::::::k     e:::::::::::::::::e      y:::::y y:::::y                                          //
//         m::::m   m::::m   m::::mo::::o     o::::o  n::::n    n::::n k:::::::::::k     e::::::eeeeeeeeeee        y:::::y:::::y                                           //
//         m::::m   m::::m   m::::mo::::o     o::::o  n::::n    n::::n k::::::k:::::k    e:::::::e                  y:::::::::y                                            //
//         m::::m   m::::m   m::::mo:::::ooooo:::::o  n::::n    n::::nk::::::k k:::::k   e::::::::e                  y:::::::y                                             //
//         m::::m   m::::m   m::::mo:::::::::::::::o  n::::n    n::::nk::::::k  k:::::k   e::::::::eeeeeeee           y:::::y                                              //
//         m::::m   m::::m   m::::m oo:::::::::::oo   n::::n    n::::nk::::::k   k:::::k   ee:::::::::::::e          y:::::y                                               //
//         mmmmmm   mmmmmm   mmmmmm   ooooooooooo     nnnnnn    nnnnnnkkkkkkkk    kkkkkkk    eeeeeeeeeeeeee         y:::::y                                                //
//                                                                                                                 y:::::y                                                 //
//                                                                                                                y:::::y                                                  //
//                                                                                                               y:::::y                                                   //
//                                                                                                              y:::::y                                                    //
//                                                                                                                                                                         //
//                                                                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract proboscis is ERC721Creator {
    constructor() ERC721Creator("proboscisfamily", "proboscis") {}
}
