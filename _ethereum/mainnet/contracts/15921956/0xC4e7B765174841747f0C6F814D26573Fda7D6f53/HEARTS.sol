
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Vicente Ortiz Cortez: Beating Hearts
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                   //
//                                                                                                                   //
//                                                                                                                   //
//                                                    @X@                                                            //
//                                                  @X@@@X@                                                          //
//                                                  X@X@X@X         @,                                               //
//                                   /@,          ,@@     @@      (X@X@X@X@X@X&   @@@@@@,                            //
//      @                       @@X@X@X@X@X@      X@       @@    @X@X@X@X@X@X@X@X  @@X@X@@@      @@@,                //
//     @X@    X@,   @#        @X@X@X@    X@X@     @X@     @@  @X@X@X@X@X@X@X@X@X@@  @X@@X@@)  @@@X@X@@@@             //
//        &X@X@X@X@(X@(      @X@X@X@  @@X@X@       @X@   @X&X@X@X@X@X       X@X@X@  @X@@@X@  @@XX@@@@XX@@            //
//       @X@X@X@    '@X@    @X@X@X@X@                X@X@X@X@X@X@X@X  @X@X@X@X@X@   @X@@@X@  @@@@@  @@X@@            //
//       X@X@X         @X@  X@X@X@X@X@X@,        .X@X@X@X@X@X@X@X@X@  @@X@X@X@X@    #@X@@@X@       @@XX@@            //
//         @X@    %@*    X@ @X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@   @X@X*   @X@  @@X@@@X@@@@@@@@XX@@             //
//      @X@X@X@    *@0    X@X@X@X@X@X@ @X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@@, @X@X@X@X@  @@X@X@X@X@X@X@@@@              //
//            X@X         /X@X@X@X@X@   @X@X@X@X@X@X@X@X@X X@X@X@X@X@X@X@X@X@X@X@X@X@   @@@@@@@@@@@@   *@X@X@X       //
//               (X@X@X   X@X@X@X@X@X   X@X@X@X@X@X@X@X@X   X@X@X@X@X@X@X@X@X@X@ @X@X@X@&             X@X@X@X@X@     //
//                  @X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@   @X@X@X@X@X@X@X@X@X@   @X@X@X@X@X@X@X@X@X  @X@X@  X@X     //
//             @X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X   X@X@X@X@X@X@X@X@X@X#      X@X@     //
//           X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@ @X@X@X@X@X@X@X@X@X X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@      //
//          X@X@X@   @X@X@X@X@X@X@X@X@X@X@X@X@   @X@X@X@X@X@X@X@X   X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X%       //
//          @X@X@  X   X@X@X@X@X@X@X@X@X@X@X@X   X@X@X@X@X@X@X@X@   @X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X           //
//           @X@X@X@X  @X@X@X@X@X@X X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@                           //
//             X@X    @X@X@X@X@X@.   @X@X@X@X@X@X@X@X,  %X@X@X@X@X@X@X@X@X               X@                          //
//                   @X@X@X@X@X@X@X#     X@X@X@X@X@      @X@X@X@X@X@X@                    X@                         //
//                   X@X@X@X@X@X@X    %,   @X@X@X@   ,;  X@X@X@X@X@X&                      X@                        //
//                   @X@X@X@X@X@X@X  @X@X@X  X@X*  X@X@X  X@X@X@X@X                        (X@                       //
//                @X X@X@X@X@X@X@X@  X@X@X@X  X@  X@X@X.  @X@X@X@X@       o@X@              @X                       //
//                 @X@X@X@X@X@X@X@X@  &@X@X@  @X&  X@X  ,@X@X@X@X@    #.     @X@X@X@X@X@X    @@                      //
//                   X@X@X@X@X@X@X@X@X   *@X  X@X      X@X@X@X@X@X  @X@X@X@X@X@X@X@X@X@X@X@  X@#                     //
//                   @X@X@X          @X@X@            X@X&X@X@X@X@                           @X                      //
//                   X@X@X@X@    X@X@   @                 @X@X@X@X          @X@X@X@X@X@X@   ,X@                      //
//                    X@X@X@X@X                %*         X@X@X@X@     @X@X@X@        X@X@   @X@                     //
//                  @X@X@X@X@X@X@X@X@X@X       @X)   %.    ,@X@X@X,            @X@X@X@  &      @X@                   //
//                     @X@X@X@X@X@X@X@X@             X@)    X@X@X@X                               X@                 //
//                      @X@X@X@X@X@X@X@        %*             @X@X@X                               *X@               //
//                        X@X@X@X@X@X@X@X@     X@)   %       @X@X@X@X@                         ,@,   @X@             //
//                       .@X@X@X@X@X@X@X@X@X         @X@     X@X@X@X@X@X                    @X@        X)            //
//                         %X@X@X@X@X@X@X@X@          #/     @X@X@X@X@X@X@X.                X@     oX@X*             //
//                             X@X@X@X@X@X@X@X@X@X           X@X@X@X@X@X@X@X@X@&             X@X@X*                  //
//                                X@X@X@X@X@X@X@X@X@X@    X@X@X@X@X@X@X@X@X@X@X@X@X@             @X                  //
//                                  @X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@X@ @X@X@X@X@X@X@X@X@           @X@                //
//                                        (@X@X@X@X@X@X@X@X@X@X@X@X@   @X@X@X@X@X@X@X@X@X      @X@X@                 //
//                                              @X@X@X@X@X@X@X@X@X@X   X@X@X@X@X@X@X@X@X@X@X@X@X@ @X                 //
//                                                     &X@X@X@X@X@X@X@X@X@X@X@X X@X@X@X@X@X@X    @X@                 //
//                                                        @X@X@X@X@X@X@X@X@X@X   X@X@X@X@X@X@   @X,                  //
//                                                         @X@X@X@X@X@X@X@X@X@   @X@X@X@X@X@     @X@X@X              //
//       Vicente Ortiz Cortez                                  X@X@X@X@X@X@X@X@X@X@X@X@X@X       X@X@X@.             //
//       Beating Hearts                                            @X@X@X@X@X@X@X@X@X@X@X@X%*@X@X@X@X@X              //
//       2022                                                           *X@X@X@X@X@X@X@X@X@X@X@X@X@X@X               //
//                                                                             &X@X@X@X@X@X@X@X@X@X                  //
//                                                                                                                   //
//                                                                                                                   //
//                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HEARTS is ERC721Creator {
    constructor() ERC721Creator("Vicente Ortiz Cortez: Beating Hearts", "HEARTS") {}
}
