
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FloodingFactoryArtPass
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//    kxxxkxxxxkkkkkkxxxxxkkc................                        .cxkkkkkkOkkkkkkkkkkkkkkkkkxkkxkkkkkkkkkkkkkkkkkkkkkkxxkkxkkxkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    xxxxxxxxxkkxxxkxxxxxxd,....... ... ..    ...                    .'cdkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxkkkkkkkkkkkkkkkkkkkxxxxkkkkkkkkkkkkkkkkkkkkkOkkk    //
//    xxxxxxkkkkxxxxxxxxxxx:..........  ..      ..                      ..,coxkkkkkkkkkkkkxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    xxxxxxxkkkxxxxxxxxxxl............ .. .                             . ..',;cclodxxxkkkkkkkkkkkkkkkxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    xxxxxxxkxxxxxxxxxxkd,.............  ..                              ..... .....',,;;::cccclllooodddxxkkkkkkkkkxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    xxxxxxxxxxxxxxxxxxx:.................                                  ...........................'',;;:cloodxkkkkkkkkkkkkkkkkkkkkkOOkkkOOkkkkkkkkkkkk    //
//    xxxxxxxxxxxxxxxxxxo'...........'. .....     .':.        ...           ... ..................................',;:lodxkkkkkkkkkkkkkkkkkkO00OOkkOkkkkkOOk    //
//    xxxxxkkxxxxxxxxxxkc..............',....   .  ...        .;,..         ....... ....................................',:ldkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    xxxkkkxxxkkkxxxxxx:...............'.......           ..:loool;.      ...... ...........................................,coxkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    kxxkkkxxxxxxxxxxxx:.......................          .,ddc'.'cdl.    ....... ..............................................;okkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    xxxxxxxkkxxxxxxxxx:................. .........      'od:.   .,ol.   .   ..............''....................................lkOkkkkkkkkkkkkkkkkkkkkkkk    //
//    xxxxxxxxxxxxxxxxxxl..............':::;,........    .cxl.     .,oc.     ................'.....................................cxkkkkkkkxxkkkkkkkkkkkOOk    //
//    xxxxxxxxxxxxxxxxxxd,...........'cddc:cdo,....... ..,ox;.      .:o;.   ... ...................................................'okkkkkkkkkkkkkkkkkOOkkOO    //
//    xxxxxxxxxxxxxxxxxxx:..'.......,oxl'...'ld:.....    ,dd,        .ll.   .  .    ................................................;xkkkkkkkkkkkkkkkkkkkkkk    //
//    xxxxkxxxxxxxxxxxxxxo,.........:xo'.....'cd:. ..    ,dd,      ...;d;.   . .   ..................................................lkkkkkkkkkkkkkkkkkkkOOk    //
//    xxxxkxkkxxxxxxxxxxxxc........'ox:........ll.       .ox;.     .. .lo.    .......................................................;xkkkkkkkkkkkkkkkkkOOOO    //
//    xxxxxxkkxxxxxxxxxxxxd;.......;dd,........,o:.      .:xl..'''..  .,d:...  ... ............................'......................:xkkkkkkkkkkkkkkkkkOO0    //
//    xxxkxxkkxxxxxxxxxxxxxo,......;do,....... .co'      .,odl;..;;,.  .:d;..  .  ..'..................................................:xkkkkkkkkkkkkkkkOO00    //
//    xxkxxkxxxxxxxxxxxxxxxxc......,dd;.........'oc.     .';dd, .cl:;'. .co;.      .....................................................;dkkkkkkkkkkkOkkOOOO    //
//    xxxxxxxxxxxxxxxxxxxxxxo,.....;oxc........ .:o,.      .:dl..,ooll,. .cd:. .   ......................................................'lxkkkkkkkkkkkkkkO0    //
//    xxxxxxxxxxxxxxxxxxxxxxd;.....,cdo:,,',,....'ol'..     .cdc..,ddc;,..,col,. ..............,:,.........................................:xkkkkkkOOOOOO000    //
//    kkkkkxxxxxxkxxxxxxxxxxd;.......cxo,..:c:,...,ol.     ...cdc..;do;;,.'''ldl,.. ............'...........................................,okkkkkOO000OOO0    //
//    kkkkkxxxxxxxxxxxxxxxxxo'.......'od:..cdc;,. .;ol.    ....cdc..'c:.,,...':oddl;'...........................'.............................:dkOOOkkO0OOOO    //
//    kkkkkxxkkkxxxxxxxxxxxd:.........,do,.'ld:,;. .,oo,.      .:dc,';::clc:::::cccc:,..........................................................;okkkOOOkkkk    //
//    kkkkkkkkkkxxxxxxxxxxxc...........:do,.'ldc;;. .'ldc..     .,cc:;,,'.........................................................................,cxOOOkkkO    //
//    kkkkkkkkkkkkxxxxxxxx:.......'...'cldo,.'cdc,;....;do;.      .       .................................'.........................................;lxkkkk    //
//    kkkkkkkkkkxxxxxxxxd;........'......;oo,..,;..:;;:::;'..         ............'.....................................................................;lxk    //
//    kkkxxkkkkxxxxxxxxl,.................,od:..';:c:;'............  ...   ..................................................... ........'.............. .':    //
//    kkkkkkkkxxxxkkkd:.........'..........:dxocc:'....................',;;::cccccc:::;;,''............................................................ ....    //
//    kkkkkkkkkkkkkko,.........co;.........'ldc,...............',;:clodxxxxxxxxxxxxxxxxxxxdoolc;,'...............................'..........................    //
//    kkkkkkkkkkkkxl'..........''....'......;;,;'..........,:lodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdoc,.......................................................    //
//    kkkkkkkkkkkkl...........................:o;......,:lodxxxxxxxxxxxkxddollloocccccccloodxkxxxxxxxo:.....................................................    //
//    oodxkkkkkkko'................................':ldxxxxxxxxxkkxdlll:,'.....;;,..  ..':,.,;coxxxxxxxo;................................................:d0    //
//    kxxdoldxkkx;................''............,:ldxxxxxxkkxdoc:;'...,,......'..'''..''..''...,;:oxxxxxxc........................................... .lOXXX    //
//    XXXX0xclxko'.........'.................,:odxxxxxxxdoll:'........'........ ...................lxxxxxkc..........................................;OXXXXX    //
//    KKKKKXk:lkl................'.........,ldxxxxxxdl:,...,;''.....''..'.      ...................:xxxdxkk:..........................,,........... ;0XXXXXX    //
//    000K0Ol:dko................'.......,ldxxxxkdll;.....''...'...... ... ..   ..,,...'...,''''..,oxxdxxkko..........................''..........  ;0XXXXXX    //
//    Oxdolccdkkx;......................:dxxxxxdc'.';'.','........ ..   ........','.   .';,....'codxxxxxxkOo.....................................,ldx0XXXXXX    //
//    lllldkkkkkkd;....................cxxxxxxo,...,............'''....''.....,c:;,;;::cldoccloxxxxxxkkkkkx;....'............................. .dXXXXXXXXXXX    //
//    OOOkkkkkkkkkx:..................cxxxxxxl;;'.'........,'...,....':lccloddxxkkkkOkkkkkkkkkkxxkkkkkkkko;................................... 'ONXNNNNNNXXX    //
//    OOOkkkkkkkkkkko,...............,dxxxxxx:....,'....','''.,:;;cldxkkkkkkkkkkkkkkkkkkkxxkkkkkkkkkkxdl;..................'c;...............   'lllooodx0XX    //
//    OOkkkkkkkkkkkkkxl'.............;dxxxxxko,.';c;''',,..,;:lxkkkkxxkxxxkkkkkkkkkkxxxxdddddoollcc:c;....................;oxdc'..... ...,;:cloddxxkkkkkO0XX    //
//    OOOkOkkkkkkkkkkkkxc'...........'oxxxxxxxdlc'..',:oooxkkkkxxkkkkkkkxdol:;,,,''''.....................................,cdo;....';ldk0KXNNXXXXXXXXXXXXXXX    //
//    00OOOOOOkOOOkkkkkkkxo:'.........,dxxxxxxxxxdddxxkkxxxxxxkkkkkxdl:,....         .   ... ...............................;,...cxKXXXXXXXXXXXXXXXXXXXXXXXX    //
//    00OOOOOkkOOOOOkkOOOOkkxo:'.......,oxkkxxxxxxxxxxxxxxxkkkkxoc;'..    ...  .         ......................................:0XXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    OOOOOOOOOOOOOOOOOOOOOkOOkxl;.......,:ldkkkkkkkkkkkkkxdl:,..    ...    ... ....     .................................... .dXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    OOOOOOOOOOOOOOOOOOOOOOOOkkOkdc,........,;cllooollc;,...        ..     ... ...     ...  ...........................   ...':odxk0XXXXXXXXXXXXXXXXXXXXXXX    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkdc;'....................      .       ....       .....  ...................... ..';:ldkO0KXXXXKXXXXXXXXXXXXXXXXXXXXXXXX    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxdl:,'...............   ...   ..     ..        ..........................':ldOKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkOOOkdl;'...........    ...   ...   .'.         ....................  .:xKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ArtPass is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
