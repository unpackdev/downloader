
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mayo
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//           .....    .....     .....            ..........  ...         .....         ....           ......                      //
//          .XXXXXX.XXXXXXX:..XXXXXXX:.       .:XXXXXXXXXXXX XXXX.      .XXXXXX.     'XXXXXX.      .XXXXXXXXXX:.                  //
//         .XXXXXXXXXXXXXXXXXXXXXXXXXX:      :XXXXXXXX:XXXXX XXXXX.    .XXXXXXXX     XXXXXXX:     :XXXXXXXXXXXXX.                 //
//         .XXXXXXXXX.:XXXXXXXX'XXXXXXX     XXXXXXXX:   .XXXXXXXXX.    'XXXXXXXX    .XXXXXXXX    .XXXXXX:    .XXX.                //
//         .XXXXXXXX. XXXXXXXX..XXXXXXX    :XXXXXXX:    .XXXXXXXX:     :XXXXXXX'    :XXXXXXXX.  .:XXXXXX.     .XXX                //
//         .XXXXXXX: .XXXXXXX. .XXXXXX:   .XXXXXXXX     .XXXXXXXX:     :XXXXXXX.   .XXXXXXXXX.  .XXXXXXXXX      XXX   .::.        //
//         'XXXXXXX. .XXXXXXX. .XXXXXX:  .XXXXXXXX:     :XXXXXXX:.    :XXXXXXX:    :XXXXXXXXX. .XXXXXXXXXXX'    :XX.'::XXX        //
//         'XXXXXXX  :XXXXXXX  :XXXXXX.  XXXXXXXXX.    'XXXXXXXX..   'XXXXXXXX:   .XXXXXXXXXX:XXXXXXXXXXXXXXXXXXXXXXX:'           //
//         'XXXXXXX  XXXXXXX:  :XXXXXX. XXXXXXXXXX:   .XXXXXXXXX..  .XXXXXXXXX:  .XXXXXXXXXXXXX::XXXXXX:.   :X:XXXX:'             //
//         .XXXXXX:  :XXXXXX.  XXXXXXX.:XX:XXXXXXXX. .XXXXXXXXXX'. :XX:'XXXXXX: .XXX.:XXXXXXX.   XXXXXXX.     .XXX.               //
//         .XXXXXX:  :XXXXXX.  XXXXXXXXXX. .XXXXXXXXXXXX..XXXXXXXXXXX.  :XXXXXXXXXX. :XXXXXX:     XXXXXXX:'  :XXX.                //
//          :XXXXX.   :XXXXX.  .XXXXXXXX.   .:XXXXXXXX:.  'XXXXXXXX:.   .:XXXXXXX.   XXXXXXX:      'XXXXXXXXXXX.                  //
//           ''''      '''''     ''''''       ''''''       ''''''        ':XX:''   'XXXXXXXX:        ''''''''                     //
//                                                                               .:XXXXXXXXX.                                     //
//                                                                              'XXX:XXXXXXX.                                     //
//                                                                             .XX:.:XXXXXXX                                      //
//                                                                            :XX:  :XXXXXX'                                      //
//                                                                           'XXX  .XXXXXXX                                       //
//                                                                          .XXX.  :XXXXXX'                                       //
//                                                                          .XX.  .XXXXXX:                                        //
//                                                                          :XX. .XXXXXX:                                         //
//                                                                          :XXXXXXXXXXX                                          //
//                                                                           XXXXXXXXX'                                           //
//                                                                            .:XxX:.                                             //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MAYO is ERC721Creator {
    constructor() ERC721Creator("Mayo", "MAYO") {}
}
