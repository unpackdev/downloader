
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: REMO
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    }}}}}}}}}}                    //
//    }}}}}}}}}}}}}}}               //
//    }}}}}}}}}}}}}}}}}}}}          //
//    }}}}}}}}}}}}}}}}}}}}}}}}}     //
//    }}}}}}}}}}}}}}}}}}}}          //
//    }}}}}}}}}}}}}}}               //
//    }}}}}}}}}}                    //
//                                  //
//                                  //
//////////////////////////////////////


contract REM is ERC721Creator {
    constructor() ERC721Creator("REMO", "REM") {}
}
