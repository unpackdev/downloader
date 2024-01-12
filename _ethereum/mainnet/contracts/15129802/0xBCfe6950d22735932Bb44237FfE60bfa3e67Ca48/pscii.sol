
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Punkscii ETH
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//    PPPPPPPPPPPPPPPPP                                     kkkkkkkk                                                iiii    iiii      //
//    P::::::::::::::::P                                    k::::::k                                               i::::i  i::::i     //
//    P::::::PPPPPP:::::P                                   k::::::k                                                iiii    iiii      //
//    PP:::::P     P:::::P                                  k::::::k                                                                  //
//      P::::P     P:::::Puuuuuu    uuuuuunnnn  nnnnnnnn     k:::::k    kkkkkkk  ssssssssss       cccccccccccccccciiiiiii iiiiiii     //
//      P::::P     P:::::Pu::::u    u::::un:::nn::::::::nn   k:::::k   k:::::k ss::::::::::s    cc:::::::::::::::ci:::::i i:::::i     //
//      P::::PPPPPP:::::P u::::u    u::::un::::::::::::::nn  k:::::k  k:::::kss:::::::::::::s  c:::::::::::::::::c i::::i  i::::i     //
//      P:::::::::::::PP  u::::u    u::::unn:::::::::::::::n k:::::k k:::::k s::::::ssss:::::sc:::::::cccccc:::::c i::::i  i::::i     //
//      P::::PPPPPPPPP    u::::u    u::::u  n:::::nnnn:::::n k::::::k:::::k   s:::::s  ssssss c::::::c     ccccccc i::::i  i::::i     //
//      P::::P            u::::u    u::::u  n::::n    n::::n k:::::::::::k      s::::::s      c:::::c              i::::i  i::::i     //
//      P::::P            u::::u    u::::u  n::::n    n::::n k:::::::::::k         s::::::s   c:::::c              i::::i  i::::i     //
//      P::::P            u:::::uuuu:::::u  n::::n    n::::n k::::::k:::::k  ssssss   s:::::s c::::::c     ccccccc i::::i  i::::i     //
//    PP::::::PP          u:::::::::::::::uun::::n    n::::nk::::::k k:::::k s:::::ssss::::::sc:::::::cccccc:::::ci::::::ii::::::i    //
//    P::::::::P           u:::::::::::::::un::::n    n::::nk::::::k  k:::::ks::::::::::::::s  c:::::::::::::::::ci::::::ii::::::i    //
//    P::::::::P            uu::::::::uu:::un::::n    n::::nk::::::k   k:::::ks:::::::::::ss    cc:::::::::::::::ci::::::ii::::::i    //
//    PPPPPPPPPP              uuuuuuuu  uuuunnnnnn    nnnnnnkkkkkkkk    kkkkkkksssssssssss        cccccccccccccccciiiiiiiiiiiiiiii    //
//                                                                                                                                    //
//                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract pscii is ERC721Creator {
    constructor() ERC721Creator("Punkscii ETH", "pscii") {}
}
