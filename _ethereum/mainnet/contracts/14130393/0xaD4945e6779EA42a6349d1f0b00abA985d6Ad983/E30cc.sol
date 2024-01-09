
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: E30 crypto club
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkc;;;;;;;;;;;;;;;;;;;oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXOl:loooooooooc. .lolool:,oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNkc;:dKWMMMMMMMMMX; cNMMMMMNk:,lKWWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWNkc:dkKWMMMMMMMMMMXl.;0WMMMMMMMNk:',lk0NWWWWWWWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMNOddddddddddddddddc..;llllllllllllll:. 'lllllllllll:. ..,lddddddONMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWNk:'''''''''''''''''''''...''.'.......''''.''..''''''''''''''''':kNMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWKo;'','''........'',',,'''''''',''....',''''''''.........''''''''cKWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMKl,'''''..  ..... ..'''..........................  .....  ..'''''':kNMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMk'..,,,.  .,:cc:,.. ...........................  .';ccc;'. ..,'''..,OWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMKl,'','. .:ccccccc' .',,,,,,,,,,,,,,,,,,,,,,,,...,ccccccc;...'',''.'c0WMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMKoccccoxl,:cccccc:,ckxlccccccccccccccccccccccclo;,ccccccc,;olcccccccoKWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWWNNNNWMXx:;:cc:;;oKMWNNNNNNNNNNNNNNNNNNNNNNNNWNOc;;:cc;,cONWNNNNNNNWWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWKxodddd0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkodddokNMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    #######  #####    ###                                                                                   //
//    #       #     #  #   #      ####  #####  #   # #####  #####  ####      ####  #      #    # #####        //
//    #             # #     #    #    # #    #  # #  #    #   #   #    #    #    # #      #    # #    #       //
//    #####    #####  #     #    #      #    #   #   #    #   #   #    #    #      #      #    # #####        //
//    #             # #     #    #      #####    #   #####    #   #    #    #      #      #    # #    #       //
//    #       #     #  #   #     #    # #   #    #   #        #   #    #    #    # #      #    # #    #       //
//    #######  #####    ###       ####  #    #   #   #        #    ####      ####  ######  ####  #####        //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract E30cc is ERC721Creator {
    constructor() ERC721Creator("E30 crypto club", "E30cc") {}
}
