// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: On-chain editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                       .............         ...........                                                                                        //
//                                                                                 ........... .. .';:clllllllcc;,'.. ...........                                                                                 //
//                                                                            ...............,,',cx0XNNNNNNNWWWWWNK0koc,..............                                                                            //
//                                                                        ...............':odlcok0KKKKXXXXXXNNNNWWMMMMMN0d:...............                                                                        //
//                                                                    .................;dO0x:cxOO00000KKKKXXXXXNNWMMMMMMMMWKd;...............                                                                     //
//                                                                 ..................:x0K0o;lxkkkOOOO0000KKKKXXXXXNNWMMMMMMMMNx;.................                                                                 //
//                                                               ..................,x0KKKd;ldxxxxkkkkOOO0000KKKKKXNNNNWMMMMMMMMXd..................                                                               //
//                                                            ....................cOKKKXk:cooddddxxxkkkOOOO0000KKKXWWWNNWMMMMMMMWO,.................. ..                                                          //
//                                                          .....................l0KKKK0l;llloooddddxxkkkOOOO000000KXWWNNWMMMMMMMM0,.....................                                                         //
//                                                        ......................c0KKKKXk::llloooodddxxxxkkkkOOOOO0000KNWNXNMMMMMMMMO'...............''.....                                                       //
//                                                      .......................,kKKKKKXx;:llloooodddxxxxkkkkkkOOOOOO00KXNXKNMMMMMMMWo..............,,.......                                                      //
//                                                    .........................l0KKKKXXx;cllloooodddxxxxkkkkkkkkkOOOO0000KKKNMMMMMMM0,...........';'..........                                                    //
//                                                  ..........................'xXKKKXXXk::lllooooddddxxxkkkkkkkkkkkOOOO0000KXWMMMMWWXc..........,:'.............                                                  //
//                                                 ...........................;KWXKKXXX0c;lllloooddddxxxkkkkkkkkkkkkkOOOO000KXNNNNNNNl.........::................                                                 //
//                                               .............................:KMNKKXXXXx;cllloooodddxxxxkkkkkkkkkkkkkkOOO000KKKXXXNXc.......'c;...................                                               //
//                                              ..............................;0MNKKXXXXKo;cllooooddddxxxkkkkkkkkkkkkkkkOOO000KKKXXN0;......;c,.....................                                              //
//                                             ...............................'kMWXKXXXXXKl;clloooddddxxxxxkkkkkkkkkkkkkkOOO000KKKXNk'....':l,......................                                              //
//                                            .................................lNNKKKXXXXNXd;clooooddddxxxxxkkkkkkkkkkkkkOOOO00KKKXXl....,lc'.......................                                              //
//                                          .............';ccc:,...............'xKKKKXXXXNWNOc:cooooddddxxxxxkkkkkkkkkkkkkOOO000KKXk,...;l:.........................                                              //
//                                         .........,:ldkKNNNNX0d;...........''.;kKKKKXXXNWWWNkl:coooddddxxxxxxkkkkkkkkkkkkOOO000KKc.'':o;.........................    ..                                         //
//                                 ......',,;:cldxOKXWWWNNNNNNNXKOc...........,::lOKKKKXXXNWWWWNOocclodddddxxxxxxkkkkkkkkkkkkkOO0Ko..'cl,..........................    ...                                        //
//                            ;dkkOOO00KKXNWWMMMMWWWWWWNNNNNNNNNXK0o'....';cdk0KKdlkKKKXXXNNWWWWMWKxl:lodddddxxxxxdlllooooooooodddc::lol:cccccccccccccc:'.........     ...                                        //
//                           .kWWMMMMMMMMMMMMMMMMMMMXO0KXWWWWNNNNXKKx;;ok0XWNNXXX0ocd0KKXXXNNWWWWWMMNOlclddddddddl,,;:cccccccccccclllllooooddddxxxxkkkOOOc........    .....                                       //
//                            ,OWMMMMMMMMMMMMMMMMMWOx0NMWWWWWWNNNXXXKOddKNNNNXK00Okxllx0KKXXXNNWWWWWWXKd:ldddddoo;.',;;;;;;;;;;;;;:::cccclllooooddddxxxxOk;.......    ......                                      //
//                             .cONMMMMMMMMMMMMMMWOxXMMMMMWWWWWNNXXXXK0xoxkkxdddkkkkkdlld0KXXXXNNWWWWWWKl:oooddoo;.,,;;;;;;;;;;;;;;:::ccccllloooodddxxxxkk;......    ........                                     //
//                               .,cdOKXNNWWWWNXKOlkMMMMMMMWWWWNXXXXXXKK0o::oxkkkkkkkkkdc;cd0XXXXXNWWWWWd;llooool;.,,;;;;;;;;;;;;;;::::ccccllloooodddxxxkk;......    ........                                     //
//                                   .,dkOOOOOOOOOxdKMMMMMWWWNNXXXXXXXKKKKOolooooddxxddl'   .cxKXXXXNNNWk::cooool;.,,;;;;;;;;;;;;;;;::::ccclllloooddddxxkk;.....     ........                                     //
//                                   .xWWWWWWWWWWWW0xkKNWWNNNNXXXXXXXXKKKK0xlcdk0KNWWWN0d;    .;xKXXXNNNO:,:lloll,.,,;;;;;;;;;;;;;;;;:::cccclllooooddddxkk;.....    ..........                                    //
//                                   .;kNWMMMMMMMMMWKocdkkOO0000OOkk0KKKOddxOXNNNWWMMMMMMNk'    .:kKKXXN0c';lllll,.,,;;;;;;;;;;;;;;;;;:::cccclllooooddddkk;.....    ..........                                    //
//                                     .,coxOOOOOOOOkk0XK0Okkkdc:oxkOkxddkKXNNNWWMMMMMMMMMMK;     .o0KXXXo';cllll,.,,;;;;;;;;;;;;;;;;;;:::ccclllloooodddxk;....     ..........                                    //
//                                    ...........dKNNNNWWWWXOxodkkddxxkKXXXNNWWMMMMMMMMMMMMMK:      ;kKKXkl:;llcc,.',;;;;;;;;;;cdkO00kxl::ccccllllooodddxk;....    ...........                                    //
//                                    ...........':odxxxdl:',okdddk0XXXK0OOOOO00KXNWWMMMMMMMWKl.     .lk0kxl,:cc:'.',;;;;;;;;ckXMMMMMMMNOocccccllloooodddkd:...    ............                                   //
//                                   ........................'cx0XXXXK0OkkkkOOkkkkOOOOOOO0KXNNNOc'..;::cdkOO0KXK0Okdoc,,,;;;:kWMMMMMMMMMMNOoccccllloooodddxkdc'    ............                                   //
//                                   ........................l0KKXXNNNWWWWWMMMMMMMMMWNXK0OOOOOOOkxddxkONMMMMMMNK0OOkOOkl,,;;lKMMMMMMMMMMMMMN0dcclllloooddddxxkko,. ............                                   //
//                                   .......................:OKKXXXNNNWWWWWMMMMMMMMMMMMMMMMMMWNXkd0XWMMMMMMMMMWNXXKK0Okl,,;;:OWMMMMMMMMMMMMMMN0dllllloooddddxxxkOdc'...........                                   //
//                                   .......................;OKKXXXXNNWWWWWMMMMMMMMMMMMMMMMMMMNXO0MMMMMMMMMMMMWKOOkkkk0x;,;;;c0WMMMMMMMMMMMMMMMNOolllooooddddxxxkkOkl..........                                   //
//                                    .......................;x0XXXXXXNNWWWWMMMMMMMMMMMMMMMMMMNN0kXWMMMMMMMMMMMMMMMWN0Ol,,;;;oKMMMMMMMMMMMMMMMWXklcllloooodddxxxxkxl;..........                                   //
//                                    .........................:oxk0XXXXNNNNNWWWWWWWWWWWWWWWWNNNKxdkO0XNWWWNKOkkkdodxO0l,,;;c0MMMMMMMMMMMMMMWKxlccclllloooddddxxoldkk;........                                    //
//                                    ......................,:lddooodddxxkOOO00KKKKKKK000OOkkkkkkkkxc:odxxxdddxkOl.'';l:,;;;lKMMMMMMMMMMMMWKxc::cccclllooooddollx0WWO,........                                    //
//                                    ....................'lx0000OOOOkxdddoodddddxxxxxkkkkOO0KXNNNO:;oxkO00KKKXXXd'',;cdl;;;;xNMMMMMMMMMWKdc;;:::ccccllloool:;o0K0Okxl........                                    //
//                                     ...................,dO0KKKKKKKKKKKKKKKKKXXXXNNNNNNNWWWWWWXd;',,;:cloodxkO0o'',;,:oo:;;:o0NMMMMMN0d:;;;;::::cccllloocclcdOOO0NNx........                                    //
//                                     ....................,xKKKKKKKKKKKKXXXXXNNNNNWWWWWWWWWWMW0c,,;;;;;;,,,,,,;;'.,,;;;;od:;;;:ldxxxdl:;;;;;;;::::ccclloxoxdlk000OOko.......                                     //
//                                      ....................'o0KKKKKKKKXXXXNNNNNNWWWWWWWWWWWWXo,,;;;;;;;;;;;;;;;;'.,,;;;;;ldc;;;;;;;;;;;;;;;;;;;:::cccccoxoxOco0O00XXx'......                                     //
//                                      ......................;xKKKKKKXXNNNNNNNNWWWWWWWWWWWNx;',,,,,,,;;,,,;;;;,;..,,;;;;;,cdl;;;;;;;;;;;;;;;;;;::::ccccoxc:l;,coolc;.......                                      //
//                                       ......................'ckKKKXXNNNNNNNNWWWWWWWWWWNk:',,,,,,,,,,,,,,,,,,,,..,,;;;;;;,:oo:;;;;;;;;;;;;;;;;;::::ccclx;.....    ........                                      //
//                                        ......................',cx0XXNNNNNNNWWWWWWWWWNk:'',,,,,,,,,,,,,,,,,,,,,..,,;;;;;;;,;lo:;;;;;;;;;;;;;;;;;:::ccclx;.....     ......                                       //
//                                        ....................  .'',:oOXNNNNNWWWWWWWWXx:'',,,,,,,,,,,,,,,,,,,,,,,..,,;;;;;;;;,;cdc;;;;;;;;;;;;;;;;;:::cclx;......    .....                                        //
//                                         ................       ....':xKNNWWWWWWN0o;''''''''',,,,,,,,,,,,,,,,,,..,,;;;;;;;;;;,:ol;;;;;;;;;;;;;;;;:::::ld;......     ...                                         //
//                                          .............        ........,cdOKNN0xc'.''''''''''''''''''''''''''',..',;;;;;;;;;;;,:ol:;;;;;;;;;;;;;;;::::ld,.......    ..                                          //
//                                           ........           .............,:;'..'''''''''''''''''''''''''''''''...'',,,,,,,,,,',lo;,,,,,,,,,,,,,,,,;::,........                                                //
//                                            ..              ........................'''''''''''''''''''''''''''''.................;c,...........................                                                //
//                                                      ..  .............................'''''''''''''''''''''''''''''''''''''.......;l;...........................                                               //
//                                           .. ...   ... ....................................'''''''''''''''''''''''''...............,c:..........................                                               //
//                                        ....    .....................................................................................'::'........................                                               //
//                                             ..........................................................................................;:'.....................                                                 //
//                                           ....   ......................................................................................,:,..................                                                   //
//                                        .            ....................................................................................':,................                                                    //
//                                                       ....................................................................................;;.............                                                      //
//                                                         ...................................................................................,;..........                                                        //
//                                                           ...................................................................................,.......                                                          //
//                                                             ..................................................................................,...                                                             //
//                                                               .................................................................................'..                                                             //
//                                                                   ...........................................................................  ....                                                            //
//                                                                      ....................................................................        ...                                                           //
//                                                                         ..............................................................            ..                                                           //
//                                                                              ....................................................                                                                              //
//                                                                                    ........................................                                                                                    //
//                                                                                            .........................                                                                                           //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CHAIN is ERC1155Creator {
    constructor() ERC1155Creator("On-chain editions", "CHAIN") {}
}
