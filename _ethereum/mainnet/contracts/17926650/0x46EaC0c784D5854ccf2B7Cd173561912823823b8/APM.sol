// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Aikopic
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                  S;;;;;;;;;-.``.7i,                                        //
//                                                  (+;>;;>;;;;;<.```.(3,                     ............    //
//                                         `         S>;>;;>>;;;;><.`````-<, .....JgQWHMMMHHHqkkkkkkkkbbpp    //
//                                ...?"7!~  ``` .(+OVT"<!<<<<;;>;++++JgkMMMHgmmmqqqqqqqkkqkkkkbbbpppfffVVV    //
//        `  `        `  `   ..7=`    ```.`````....JS+<`...(gkMM@@@@@@gggggggHHHHHWUYYY"""""""TYUWWkyyyyZy    //
//             `   `    `.-"!     ```.`````.`.`7WQQHHMHH@H@@@@@@@MHHYY"T=?~ ````(I.                  7WZZZ    //
//                    .?^     ```.`.``.`...JgMHHH@HH@H@HMMY""=!`````````` _..`.```(i                  ,ZZZ    //
//      ` ` `   `  .?'  ```````.` ..(gMHHH@HH@HHMHY""!```````.``.``.``````.```.``.``4.              .(WZZy    //
//               .3...... ` ..+dM@@@@@@@HMY""!_`````````.``.`````.``.`.`.``````  ````4    `   `   .dWyyyyy    //
//           `    h;;;jjgHM@@@@@@@HMY"^`````````.```.``.``.``.````.````.```.`.``` .`. L       ..dHyyyyyyWk    //
//      `  `    `..HMM@@@@@@MHW9C<;;>;_-.`.`.`.``.`.``.```````.`.```.````.``.```.`````,i  ..JHWyyyyyWkY=      //
//          ..JWMggggggHHYY>;;;;;;;;;;;;;><-.``.````````.``.```.```.``.```.```.`````.```7HVVVVVWQV"^          //
//      ..dMHmmmmmgHY42;;;;;;;;;;>;;>;;>;;;><!````.`.``.``.`. .-(~````.``.```.``.``.`````OWQV"=               //
//    dMmqqqqqqHT"`   (n<;;;>;;>;;><<?!~``  ``.`.``.``.``.  (;;;````.``.```.`````.```.`.`.\                   //
//    qqkqkqH"!         7x;;;><!` ``````  `````.``.,71(..-...++!``.``.```.``.``.``.```..  4.                  //
//    kkkHY'              K!`````.``.`  ````.```.-\ ( :`` ..JJ-..?7i.......  ..```~`     _`(,     `  `  `     //
//    bbW:.,         `  .Y ```.```.`` ````.``.``(,J+v+C_.dH@@H@@@gm+.(=.                  _`(,                //
//    pWNh,(       `   .^``.```.``.````.```.``.` !``.<+_dHHHHHH@gmqbpWe.?i                 _`?, `             //
//    W@@@M[i...      .^````.```.``.``.``.```.`````.  4_M@@@H@@@gqHppf$_<.~?.              -``?,   `  `       //
//    WHHH@HJyyyVfpppbW `.```.```.```.````.`````.`.`  ,_d@@H@@@mqHpfXC<<_~i~(,            . _` G.             //
//    kWH@HHMVWWWWkkkQH;``.``.``.```.``.```.``.```.  .$<~W@@@@gmkpWSOOzz<<(r_(,   ...       _``.b       `     //
//      ?""!           ]```.``.````.``` ..``.``.``_   1+-,H@gggqkpfWXXwOzuyS(.-7=!_(?7<(.    ` `d   `         //
//                     u.```.```.````.(;;;-`````.`_      4,7HqqqHkWWyZXwwyy%..<~:(=dmmHa,.=-   .d             //
//                    .J ``````..?! `   !;;<..```.`_ `    .4,(THkHpffVVyyVf.~_((,(gmgmqqkbX,(G._r    `  `     //
//      `       `    .^```.``../          _<><-.``.          ?4-.?"UWpfWV=+(?'  ,(gg@ggqbppfYi(N]             //
//         `  `    `.^```.``..J               !<<..`.            ?7i(...J7"      <W@ggHHpp0>___-T+,           //
//                 .'``.````.;[                    ~`            `               .dggmkpWXOz+<_(- ?L          //
//                .$``.``.`..;u                                                    (4qbpyZXwwwd3:.(Y          //
//             `  ,.````.````<<L                          `                         ,HbWpyyXX0wZ.t      `     //
//       `  `       74J------(;<S.                                                  _1(4WVyyyyW\y             //
//                      ?"1+++;;>?G-.                                                 .T-/7T""!.)             //
//                            _?4J;<TG&-....      `                        `             ."u+w&k^             //
//                               .4++++;?7496.                    ...~!!~~~~...            d          `       //
//    ~..   `  `                        4+v???1.                               =`         .]                  //
//    ....~..        `                  ,6??????i. `                                     .F         `         //
//     `~`____..~_.   ......  ..J"=?4,.8??????????1.                                   .(^                    //
//        ....  ``(91(-_~.~_7-.       7z????????????=-.                            ` .J^          `           //
//    .gHHHHHMMNQmVUVSc>>..~.(-{        <z?????????????1-.         `   `   `     `.,"`                        //
//    HHHHHHHHHHHHHmOOwyz-~.(zOl`        .1???????????????<-.                 ..7^              `             //
//    HHHHHHH@HHHHHHMmlZo>+_.i  _. `       .1??????????????uZ"?=(,       ...7^                        `       //
//    HHH@HHHHHHHHHHHHNOlOz<-({  ..          _??????????1d"       ."1?7"!                 `   `               //
//    HHHHHH@HHHHHHHHHHNsltO&d| `` -   `       <z?????1d"                                                     //
//    HHHHHHHHHHHHHHHH##MslllOU.    ~           .1?1g7'                                                       //
//    HMHHHHHHHHHH###NNMNNOlllOX.                 ?b..                         `   `    `         `           //
//    __?WMH#MMMMMMNMNMMMMbtltlwn      .    `    .Jd~`.__                                     `       `       //
//    .._..?TMMMMMMMMMMMMMNllltld[      .     .dNN; ?,   `___.     `                                          //
//    mJ._._-__?WMMMMMMMMMNOtllttW.      _ .<?##HHH#+uP     `~._..                          `                 //
//    NNNNa+-__.._~TWMMMMMNZllllldL           HHHHH%(Y         ____~..   `   `   `   `            `           //
//    NMMMMMMNg+-._~._(TWMMSltttlwH         . .H@H^.%             !-.-<-.                 `                   //
//    MMMMMMMMMMMNgJ-__..~~71OrZllW;       ..(HMMH,W;                ~-._<-.                          `       //
//    MMMMMMMMMMMMMMMNg+._..___?<zdb       (dMMHdMtdH,                 _-.-_?_.                 `             //
//    dMMMMMMMMMMMMMMMMMMNk&--_....~<-.   .HY(@@JMlwW]                   .<_...?-.      `                     //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract APM is ERC721Creator {
    constructor() ERC721Creator("Aikopic", "APM") {}
}
