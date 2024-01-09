
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Spheres of Ash - The creator
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    https://twitter.com/Sph3res                                                         //
//                                                                                        //
//    https://opensea.io/collection/spheres-of-ash                                        //
//                                                                                        //
//    lllcccccccccccccccccccccccccllllllllllllllllloooooooooodddddddxxxxxxxkkkkkkkOOOO    //
//    ccccccccccccccccccccccccccclllllllllllllllllloooooooooodddddddxxxxxxxkkkkkkkOOOO    //
//    ccccccccccccccccccccccccccccclllllllllllllllloooooooooodddddddxxxxxxxkkkkkkkkOOO    //
//    cccccccccccccccccccccccccccccllllllllllllllllooooooooooodddddddxxxxxxxkkkkkkkOOO    //
//    cccccccccccccccccccccccccccccllllllllllllllllloooooooooddddddddxxxxxxxkkkkkkkkOO    //
//    cccccccccccccccccccccccccccccllllllllllllllllooooooooooodddddddxxxxxxxkkkkkkkkkO    //
//    cccccccccccccccccccccccccccccclllllllllllllllloooooooooodddddddxxxxxxxxkkkkkkkkk    //
//    ccccccccccccccccccccccccccccccllllllllllllllllooooooooooddddddddxxxxxxxkkkkkkkkk    //
//    ;::cccccccccccccccccccccccccccclllllllllllllllloooooooooodddddddxxxxxxxxkkkkkkkk    //
//    ;;;;:::ccccccccccccccccccccccccc:;;;;;;;;;;;;;:cloooooooodddddddxxxxxxxxxkkkkkkk    //
//    ;;;;;;;:::cccccccccccccccccc:;;,;;;:::::::::;;;,;:cloooooddddddddxxxxxxxxkkkkkkk    //
//    ;;;;;;;;;;::::cccccccccccc;,,;:cccccccccccccccccx0kdllooooddddddddxxxxxxxxkkkkkk    //
//    ;;;;;;;;;;;;;::::ccccccc:,,::ccccccccccccccccclONMMWKxllooddddddddddddxxxxkkkkkk    //
//    ;;;;;;;;;;;;;;;:::::cc:;,;ccccccccccccccccccclOWMMMMMWKdloddddddolcccd0Oxxxkkkkk    //
//    ;;;;;;;;;;;;;;;;::::::'.';:ccccccccc:;;,,,,,:kWMMMMMMMWXxloddddoc,''.c0XOxxxkkkk    //
//    ;;;;;;;;;;;;;;;;;:::;'.....',;:c::;'.......';o0WWMMMMWXOOdlodddol;...,x0kxxxxkkk    //
//    ;;;;;;;;;;;;;;;;;:::,...........''.........',;l0NWWWWWd'ckolddddoc;'':oxxxxxxxkk    //
//    ;;;;;;;;;;;;;;;;;::;'...'''....   .........',,;oKNNNWWKod0dloddddddooddxxxxxxxkk    //
//    ;;;;;;;;;;;;;;;;;;:;'..',;;;cc,   ..  .....'',,:kXNNNNNNNXdcoodddddddddxxxxxxxxk    //
//    ;;;;;;;;;;;;;;;;;;;;'..',,,;kNO,  ...  ......',;dXNNNNNNNKocoooddddddddxxxxxxxxx    //
//    ;;;;;;;;;;;;;;;:;:::,..'....lKKc.        .....',oKXXXXXXXOllooooddddddddxxxxxxxx    //
//    ;;;;;;;;;;;;,'''..,:;'.''. .;ol'.          ....,lOKXXXXX0ocloooodddddddddxxxxxxx    //
//    ;;;;;;;;;;;;,'...';;;,..'...',''..         ...,:ldkO0KK0o:loooooodddddddddxxxxxx    //
//    ;;;;;;;;;;;;;,'.',;;;;,'.',;;:;;,..     .....,:codxkxdl:;coooooooodddddddddxxxxx    //
//    ;;;;;;;;;;;;;;;;;;;;;::;'.',::c:,.    ......',:cloooc,';clooooooooodddddddddxxxx    //
//    ;;;;;;;;;;;;;;;;;;;;;;::;,''';;,.     ......',;;:;,'',:llllloooooooodddddddddxxx    //
//    ;;;;;;;;;;;;;;;;;;;;;;;::::;''..     .............';:clllllllloooooooddddddddddx    //
//    ,;;;;;;;;;;;;;;;;;;;;;;:::::::;,..............',;:cccllllllllllooooooooddddddddd    //
//    ,;;;;;;;;;;;;;;;;;;;;;;;:::::::::::;;;;;;;;;::cccccccclllllllllllooooooodddddddd    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;::::::::::::::::ccccccccccccccllllllllllloooooooodddddd    //
//    ,,,;;;;;;;;;;;;;;;;;;;;;;:::::::::::::::::cccccccccccccllllllllllllooooooooooddd    //
//    ,,,;;;;;;;;;;;;;;;;;;;;;;::::::::::::::::::ccccccccccccccllllllllllllooooooooood    //
//    ,,,;;;;;;;;;;;;;;;;;;;;;;:::::::::::::::::::cccccccccccccclllllllllllooooooooooo    //
//    ,,,;;;;;;;;;;;;;;;;;;;;;;;;;:::::::::::::::::ccccccccccccccclllllllllllooooooooo    //
//    ,,,,,;;;;;;;;;;;;;;;;;;;;;;;;::::::::::::::::::ccccccccccccccllllllllllloooooooo    //
//    ,,,,,;;;;;;;;;;;;;;;;;;;;;;;;;::::::::::::::::::cccccccccccccclllllllllllloooooo    //
//    ,,,,,,;;;;;;;;;;;;;;;;;;;;;;;;;:::::::::::::::::cccccccccccccccllllllllllllloooo    //
//    ,,,,,,,;;;;;;;;;;;;;;;;;;;;;;;;::::::::::::::::::ccccccccccccccclllllllllllllooo    //
//    ,,,,,,;;;;;;;;;;;;;;;;;;;;;;;;;;;::::::::::::::::::ccccccccccccccllllllllllllllo    //
//    ,,,,,,,,,;;;;;;;;;;;;;;;;;;;;;;;;;::::::::::::::::::ccccccccccccccclllllllllllll    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract SACR is ERC721Creator {
    constructor() ERC721Creator("Spheres of Ash - The creator", "SACR") {}
}
