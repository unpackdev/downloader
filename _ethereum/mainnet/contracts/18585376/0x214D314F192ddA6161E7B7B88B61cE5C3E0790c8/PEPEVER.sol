// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Together Pepever
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    O))) O))))))                               O))                                      //
//         O))                                   O))  O))                                 //
//         O))       O))       O))      O))    O)O) O)O))        O))    O) O)))           //
//         O))     O))  O))  O))  O)) O)   O))   O))  O) O)    O)   O))  O))              //
//         O))    O))    O))O))   O))O))))) O))  O))  O))  O))O))))) O)) O))              //
//         O))     O))  O))  O))  O))O)          O))  O)   O))O)         O))              //
//         O))       O))         O))   O))))      O)) O))  O))  O))))   O)))              //
//                            O))                                                         //
//    O)))))))                                                                            //
//    O))    O))                                                                          //
//    O))    O))   O))    O) O))     O))    O))     O))   O))    O) O)))                  //
//    O)))))))   O)   O)) O)  O))  O)   O))  O))   O))  O)   O))  O))                     //
//    O))       O))))) O))O)   O))O))))) O))  O)) O))  O))))) O)) O))                     //
//    O))       O)        O)) O)) O)           O)O))   O)         O))                     //
//    O))         O))))   O))       O))))       O))      O))))   O)))                     //
//                        O))                                                             //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract PEPEVER is ERC721Creator {
    constructor() ERC721Creator("Together Pepever", "PEPEVER") {}
}
