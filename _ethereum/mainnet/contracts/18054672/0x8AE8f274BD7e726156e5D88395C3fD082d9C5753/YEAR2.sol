// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 2YearPowerup
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                                                      //
//     222222222222222   YYYYYYY       YYYYYYY                                                 PPPPPPPPPPPPPPPPP                                                                                                                                        //
//    2:::::::::::::::22 Y:::::Y       Y:::::Y                                                 P::::::::::::::::P                                                                                                                                       //
//    2::::::222222:::::2Y:::::Y       Y:::::Y                                                 P::::::PPPPPP:::::P                                                                                                                                      //
//    2222222     2:::::2Y::::::Y     Y::::::Y                                                 PP:::::P     P:::::P                                                                                                                                     //
//                2:::::2YYY:::::Y   Y:::::YYYeeeeeeeeeeee    aaaaaaaaaaaaa  rrrrr   rrrrrrrrr   P::::P     P:::::P  ooooooooooo wwwwwww           wwwww           wwwwwww eeeeeeeeeeee    rrrrr   rrrrrrrrr   uuuuuu    uuuuuu ppppp   ppppppppp       //
//                2:::::2   Y:::::Y Y:::::Y ee::::::::::::ee  a::::::::::::a r::::rrr:::::::::r  P::::P     P:::::Poo:::::::::::oow:::::w         w:::::w         w:::::wee::::::::::::ee  r::::rrr:::::::::r  u::::u    u::::u p::::ppp:::::::::p      //
//             2222::::2     Y:::::Y:::::Y e::::::eeeee:::::eeaaaaaaaaa:::::ar:::::::::::::::::r P::::PPPPPP:::::Po:::::::::::::::ow:::::w       w:::::::w       w:::::we::::::eeeee:::::eer:::::::::::::::::r u::::u    u::::u p:::::::::::::::::p     //
//        22222::::::22       Y:::::::::Y e::::::e     e:::::e         a::::arr::::::rrrrr::::::rP:::::::::::::PP o:::::ooooo:::::o w:::::w     w:::::::::w     w:::::we::::::e     e:::::err::::::rrrrr::::::ru::::u    u::::u pp::::::ppppp::::::p    //
//      22::::::::222          Y:::::::Y  e:::::::eeeee::::::e  aaaaaaa:::::a r:::::r     r:::::rP::::PPPPPPPPP   o::::o     o::::o  w:::::w   w:::::w:::::w   w:::::w e:::::::eeeee::::::e r:::::r     r:::::ru::::u    u::::u  p:::::p     p:::::p    //
//     2:::::22222              Y:::::Y   e:::::::::::::::::e aa::::::::::::a r:::::r     rrrrrrrP::::P           o::::o     o::::o   w:::::w w:::::w w:::::w w:::::w  e:::::::::::::::::e  r:::::r     rrrrrrru::::u    u::::u  p:::::p     p:::::p    //
//    2:::::2                   Y:::::Y   e::::::eeeeeeeeeee a::::aaaa::::::a r:::::r            P::::P           o::::o     o::::o    w:::::w:::::w   w:::::w:::::w   e::::::eeeeeeeeeee   r:::::r            u::::u    u::::u  p:::::p     p:::::p    //
//    2:::::2                   Y:::::Y   e:::::::e         a::::a    a:::::a r:::::r            P::::P           o::::o     o::::o     w:::::::::w     w:::::::::w    e:::::::e            r:::::r            u:::::uuuu:::::u  p:::::p    p::::::p    //
//    2:::::2       222222      Y:::::Y   e::::::::e        a::::a    a:::::a r:::::r          PP::::::PP         o:::::ooooo:::::o      w:::::::w       w:::::::w     e::::::::e           r:::::r            u:::::::::::::::uup:::::ppppp:::::::p    //
//    2::::::2222222:::::2   YYYY:::::YYYY e::::::::eeeeeeeea:::::aaaa::::::a r:::::r          P::::::::P         o:::::::::::::::o       w:::::w         w:::::w       e::::::::eeeeeeee   r:::::r             u:::::::::::::::up::::::::::::::::p     //
//    2::::::::::::::::::2   Y:::::::::::Y  ee:::::::::::::e a::::::::::aa:::ar:::::r          P::::::::P          oo:::::::::::oo         w:::w           w:::w         ee:::::::::::::e   r:::::r              uu::::::::uu:::up::::::::::::::pp      //
//    22222222222222222222   YYYYYYYYYYYYY    eeeeeeeeeeeeee  aaaaaaaaaa  aaaarrrrrrr          PPPPPPPPPP            ooooooooooo            www             www            eeeeeeeeeeeeee   rrrrrrr                uuuuuuuu  uuuup::::::pppppppp        //
//                                                                                                                                                                                                                               p:::::p                //
//                                                                                                                                                                                                                               p:::::p                //
//                                                                                                                                                                                                                              p:::::::p               //
//                                                                                                                                                                                                                              p:::::::p               //
//                                                                                                                                                                                                                              p:::::::p               //
//                                                                                                                                                                                                                              ppppppppp               //
//                                                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract YEAR2 is ERC1155Creator {
    constructor() ERC1155Creator("2YearPowerup", "YEAR2") {}
}
