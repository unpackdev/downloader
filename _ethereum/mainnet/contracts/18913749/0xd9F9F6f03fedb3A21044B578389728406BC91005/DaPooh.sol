// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DaPooh
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                     //
//                                                                                                                     //
//     ;!!!` `!!!!!!!!!!!!'''..,,,,umc9M=                                                                              //
//                                       ;!'',n `!!!!!!!!'' ,nbmMMMMMMMMMMMb,                                          //
//                                       !'.dMMM,.````.,,ndMMMMMMMMMP".,c,"Mb                                          //
//                                       ! dMMMMMMMMMMMMMMMMMMMMMMM" d$$$$c                                            //
//                                     ,'' '4MMMMMMMMMMMMMMMMMMMMMP $$$$$$$                                            //
//                                 ,nn, ,="= "4MMMMMMMMMMMMMMMPP"' d$$$$$$$>                                           //
//                               ,dMMMM. c$c$h,."""PPPPPP""".cc  $.$$$$$$$$                                            //
//                              .nMMMMMM $$??$$$$$ccc,c,-d$$$$$ ,$d$P????"                                             //
//                              'dMMP"",cP' ,F$$$$$$$$$$ $$$$$F d$$$hcccc,                                             //
//                              `P",c"""""=cPi$$$$$$??$$h$$$$$' $$$$$$$$$                                              //
//                               .d$h       3$$$$$$'  $$$$$$$$  $$$$$$$$P                                              //
//                               $$$',    .z$$$$$$$c,J$$$$$$$F J$$$$$$$P                                               //
//                               $$$ $$cd$$$$$$$$$$$$$$$$$$$$' $$$$$$$$                                                //
//                               `$$.?$$$$$$$$$$$$$$$$$$$$$$'  $$$$$$$'                                                //
//                              M.?$L`?$$$$$$$$$$C"?$$$$$$P',M $$$$$P'                                                 //
//                             uMM "$c "$$$$$$$$P',c$$$$P" uMM $$$$P'="n,                                              //
//                            ,MMMMx`?$c,"????"',J$$$$$",nMMMM $$$P ,uMMMb.                                            //
//                            dMMMMMb,`?$hccccc$$$$$P",nMMMMMM .,,ndMMMMMM                                             //
//                           4MMMMMMMMMn,`"?????".,nnMMMMMMMMM dMMMMMMMMMM                                             //
//                           MMMMMMMMMMMMMbmnmMMMMMMMMMMMMMMMM MMMMMMMMMM'                                             //
//                        .; JMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMP' MMMMMMMMM'                                              //
//                   ..;!!!! MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM> JMMMMP"                                                  //
//                .;!!!!!!! ,MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMP PPP"".;.                                                  //
//              ;!!!!!!!!! '4MMMMMMMMMMMMMMMMMMMMMMMMMMMMM' .;;;!!!!!;                                                 //
//             ''!!!!!!!' <'4MMMMMMMMMMMMMMMMMMMMMMMMMMMP' ;!!!!!!!!!!!                                                //
//      nmMMMMbn.`'!!!!! ;!.`MMMMMMMMMMMMMMMMMMMMMMMMMM"  `!!!!!!!!!!!!!!!!                                            //
//      !!!!!!!; "P",, $( =.`: )MMMMMMMMP")PP  --''''''''- ` $c -..:.`MMP".P"    .:::::......::::: `!!!!!!!!!!!!!!>    //
//    ;!!!!!!!!!' MMML ?$$c,.` ==" ., -.:::::::::::::::::::::. `!!!!!!!!!!!! Jb.                                       //
//    !!!!!!!!!'  MMMMMn,.""??hhcccJ"` :::::::::::::::::::::::' `!!!!!!!!'',dMM(                                       //
//    `!!!!!!'    MMMMMMMMMMn,,.`'   .````'''':::::::::::'''' ,P `!!!'''.,nMMMMM                                       //
//       ``       `MMMMMMMMMMMMMMMMMMMMMMbmnmnmx;;;;;;;nmnmnm 4mn,..,umdMMMMMMM'                                       //
//                  "MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM `MMMMMMMMMMMMMMP                                         //
//                    "4MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx. 44MMMMMMMMPP",>                                        //
//                      ""4MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMn.`"""""..;;!!>                                        //
//                      "cc,.""""444MMMMMMMMMMMMMMMMMMMMMMMMMMMM?? `!!!!!!!!!!'                                        //
//                       `$$$$hccccccc,.`""'.,..""""""""""""'.,cc c `!!!!!!!!`                                         //
//                        `$$$$$$$$$$$$$$$$$$$$$$$$$$$$P'.J$$$$$$h`h,`''!!''                                           //
//                         `$$$$$$$$$$$$$$$$$$$$$$$$$$".J$$$$$$$$$ $$'                                                 //
//                          `?$$$$$$$$$$$$$$$$$$$$$$$',$$$$$$$$$$$ $'                                                  //
//                            `"$$$$$$$$$$$$$$$$$$$$ ,$$$$$$$$$$$P                                                     //
//                             c`?$$$$$$$$$$$$$$$$$',$$$$$$$$$$$$'                                                     //
//                             ?$c,"?$$$$$$$$$$$$$$ $$$$$$$$$$$$F                                                      //
//                             `$$$hc,`"??$$$$$$$$F $$$$$$$$$$$$                                                       //
//                              ?$$$$$$hc,,. `"""'  $$$$$$$$$$$F                                                       //
//                               "$$$$$$$$$$        $$$$$$$$$$$'                                                       //
//                                `$$$$$$$$$        $$$$$$$$$$$                                                        //
//                                 `?$$$$$$$c       `$$$$$$$$$$                                                        //
//                           .,ccc,. "?$$$$$$,       ?$$$$$$$$F                                                        //
//                          $$$$$$$$$$c,"$$$",cccccc,."?$$$$$$'                                                        //
//                         <$$$$$$$$$$$$$$$ J$$$$$$$$$$hc$$$$$                                                         //
//                         `?$$$$$$$$$$$$$$:$$$$$$$$$$$$$$$$$$                                                         //
//                           ""???$$$$$$$$$ ?$$$$$$$$$$$$$$$$$                                                         //
//                                   `""'   `?$$$$$$$$$$$$$$P'                                                         //
//                                             `""??""""""                                                             //
//                                                                                                                     //
//                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DaPooh is ERC721Creator {
    constructor() ERC721Creator("DaPooh", "DaPooh") {}
}
