
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ze Bankerz
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                          //
//                                                                                                                                          //
//    ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddo;.:dddddddddddddddddddddddddddddddddddddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddc,..:dddddddddddddddddddddddddddddddddddddddd    //
//    dddddddddddddddddddddddddddddddddo:codddddddddddddddddddddddddddddddddddddddddddddddo',k:.cddddddddddddddddddddddddddddddddddddddd    //
//    dddddddddddddddddddddddddddddddddl..ldddddddddddddddddddddddddddddddddddddddddddddddo.,KKc'':odddddddddddddddddddddddddddddddddddd    //
//    dddddddddddddddddddddddddddddddddl..ldddddddddddddddddddddddddddddddddddddddddddddddd,.dWWKo;',:lddddddddddddddddddddddddddddddddd    //
//    ddddddddddddddddddddddddddddddddo' .cddddddddddddddddddddddddddddddddddddddddddddddddo,.c0WMN0d:,';loddddddddddddddddddddddddddddd    //
//    dddddddddddddddddddddddddddddddd,';.:dddddddddddddddddddddddddddddddddddddddddddddddddoc'.oXMMMWXkc,';lddddddddddddddddddddddddddd    //
//    ddddddddddddddddddddddddddddddd:.od.;ddddddddddddddddddddddddddolllccc:::::cclllllloddddo:',l0WMMMWXkc''codddddddddddddddddddddddd    //
//    dddddddddddddddddddddddddddddd:.:Xd.:dddddddddddddddddollc:;,'''''''''''''''''''''''',;:cloc,':kWMMMMWKo''cddddddddddddddddddddddd    //
//    dddddddddddddddddddddddddddddl.;KMd.;dddddddddddoc;,''''''',;:looddddddddddddddddddoc,'....:dl,.cXMMMMMWKc.,oddddddddddddddddddddd    //
//    ddddddddddddddddddddddddddddo''OMMk.,dddddddc,'''',;clodddddddddddddddddddddddddddddddlcc;..lddc.;KMMMMMMWk''ldddddddddddddddddddd    //
//    ddddddddddddddddddddddddddddc.cWMMX;.ldddo:'.,:coddddddddddddddddddddddddddddddddddddocccc..:ddd:.cNMMMMMMWO'.lddddddddddddddddddd    //
//    dddddddddddddddddddddddddddd,.xMMMWx.,dc'.':odddddddddddddddddddddddddddddddddddddddoccccc;.'oddo'.OMMMMMMMWk.,odddddddddddddddddd    //
//    dddddddddddddddddddddddddddd''0MMMMNl.;'.cdddddddddddd:,lddddddddddddddolc::;;;;,':olcccccc..:ddd;.dMMMMMMMMWc.cdddddddddddddddddd    //
//    dddddddddddddddddddddddddddo''0MMMMMNl..:dddllddddddddc.,dddddddool:;,'.....lddc..:olcccccc;..odd:.oMMMMMMMMMd.:dddddddddddddddddd    //
//    dddddddddddddddddddddddddddd,.xMMMMMWx.,oc,,'..,;,''',c,;ddddddl'..:oxo..c'.k0c''cdlccccccc:..cdd:.oMMMMMMMMWo.:dddddddddddddddddd    //
//    ddddddddddddddddddddddddddddl.:XMMMMK,.oc.:0d. 'oddd:..;lollllol'..:dkkl'..;;',lddolcccccccc,.'od,.kMMMMMMMMX;.ldddddddddddddddddd    //
//    ddddddddddddddddddddddddddddd:.lNMMMd.;ddc,cl. .:,... .'''''''''.....';;,'',:ldddddolccccccc:..cl.;XMMMMMMMMx.,ddddddddddddddddddd    //
//    dddddddddddddddddddddddddddddd;.dWMMd.;dddl:;,.. ..,;:clooddddol::;,''',:ldddddddddddoccccccc,.'..kMMMMMMMMO'.lddddddddddddddddddd    //
//    ddddddddddddddddddddddddddddddo:.cKMx.;dddddc'',:ldddoloool:;;:cloooooc;'',cdddddddddoccccccc;..;OWMMMMMMWO''ldddddddddddddddddddd    //
//    ddddddddddddddddddddddddddddddddc''l:.;dddo,.;odl;,'.,;,'..,cl,....,,,;:ll,.;ddddddddlccccccc,.cNMMMMMMMWx..:odddddddddddddddddddd    //
//    dddddddddddddddddddddddddddddddddol,. ;ddl..co:'.',..c0Kkc.;0WKo.  :kko;.,:..oddddddocccccccc'.dMMMMMMMNo..'''',;:lodddddddddddddd    //
//    dddddddddddddddddddddddddddddddddddd; ;dl..ll'  .;,, 'kk:;,.cd;::,..x0o;... 'odddddddlccccccc'.dMMMMMXx,.;oddol:,''.',;coddddddddd    //
//    dddddddddddddddddddddddddddddddddddd:.;d,.',...  ,kO,..,l0K; .:KX0: .,:,.'. :ddddddddlccccccc,.lWMMKo,':odddddddddoc;'...,codddddd    //
//    dddddddddddddddddddddddddddddddddddd; ;dc.  ;o: .kNXo.,ONNNd.,0NNNx..dKd.  ,oddddddddlccccccc,.lWKo''codddddddddddddlcc:;'.':odddd    //
//    dddddddddddddddddddddddddddddddol:,,..:ddc..lo,.'odl..;cccc' .:ccc;..;:;. 'odddddddddolcccccc;.'c,,cddddddddddddddddoccccc:..;oddd    //
//    ddddddddddddddddddddddddddddoc,'',;:..cddo;','''''',;::cc:::::cccccccccllloddddddddddolcccccc;..;odddddddddddddddddddolcccc:'.;odd    //
//    ddddddddddddddddddddddddddo:'.,coddo'.ldddddddddddddddddddddddddddddddddddddddddddddddlcccccc:..odddddddddddddddddddddolccccc'.,od    //
//    ddddddddddddddddddddddddo;.':odddddl.'odddddddddddddddddddddddddddddddddddddddddddddddoccccccc..ldddddddddddddddddddddddoccccc'.,o    //
//    ddddddddddddddddddddddo:..:odddddddc.,ddddddddddddddddddddddddddddddddddddddddddddddddlccccccc..lddddddddddddddddddddddddolcccc'.;    //
//    ddddddddddddddddddddo:..:odddddddddl.'oddddddddddddddddddddddddddddddddddddddddddddddocccccccc..oddddddddddddddddddddddddddolccc'.    //
//    ddddddddddddddddddo;..:odddddddddddl.'odddddddddddddddddddddddddddddddddddddddddddddddlcccccc:..odddddddddddddddddddddddddddoccc:.    //
//    ddddddddddddddddl;.':oddddddddddddd:.;ddddddddddddddddddddddddddddddddddddddddddddddddlccccc:'.,odddddddddddddddddddddddddddocccc;    //
//    ddddddddddddddo:..:oddddddddddddddd,.:ddddddddddddddddddddddddddddddddddddddddddddddolcc:;,..'cdddddddddddddddddddddddddddddolcccc    //
//    ddddddddddolcc'.;odddddddoooooddddo'.cddddddddddddddddddddddddddddddddddddddddddddol;'...',:ldddddddddddddddddddddddddddddddddoccc    //
//    dddddddddl'.   .:oddddl;.......,ldd:'''',,''',::cclllllodddddddddddddddddddolcc:;,''',;:loddddddddddddddddddddddddddddddddddddoccc    //
//    ddddddddc.       .',,'.     ..  .lddoc;,,.  .,,,,,''''''',;;;;;;,,,,,,,,,,''''',,:loddddddddddddddddddddddddddddddddddddddddddoccc    //
//    dddddddd;  .:c'.;'',       .     :dc'...... .oxddddddddl:;;;;;;;;;::::::::coddddddddddddddddddddddddddddddddddddddddddddddddddoccc    //
//    dddddddo..:ddd:.dxdO'      .     ,:.....'.. .ldddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddlcc    //
//    ddddddl'.cddddc.oWMWc               ..'lddc,:odddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddocc    //
//    dddddo'.:dddc:,.;xkx'            .    ,dddddddddddddddddl:ll,,::coddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddlc    //
//    ddddo,.:ddl''c, 'cl:.,xk;.co';c.,o;.. .,:lddddddddddddddl,'.  .'coddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddol    //
//    dddd:.,ddd;.xWd.dMWNc'OWc'0NdkXlxMk''' .':ddddddddddddddddo:.,ldddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddoc    //
//    dddo..lddd;.xWOo0WWWOoKWocKN0KWO0WOcll'.,;odddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddodddddddddddddddddddlc::;,    //
//    ddd:.,dddo, 'ccclllcclc:;:cc:;;:cclc:,';:;;;codddddddddddddddddddddddddddddddddddddddddddddddddddddddddl,:dddddddddddddddddl,',,;:    //
//    ddd,.cdddl.,x0KKKK0KKXo.lOxdl;,:dOXXKKXNNNKc.cddddddddddddddddddddddddddddddddddddddddddddddddddddddddd,.cdddddddddddddddddddooool    //
//    ddl.'odddo.;XWWWWWWX0d' .::ccc:'lXWWWWWWWWWk':ddddddddddddddddddddddddddddddddddddddddddddddddddddddddo..odddddddddddddddddddddddo    //
//    dd;.;ddddd''0WWKdc;'.''.ckOOOKd.cNWWWWWWWWWk.;ddddddddddddddddddddddddddddddddddddddddddddddddddddddddl.'ddddddddddddddddddddddddo    //
//    do..cddddd,.kM0, ..':c;..,cokO;.OWWWWWWWWWWk.,ddddddddddddddddddddddddddddddddddddddddddddddddddddddddc.'odddddddddddddddddddddddl    //
//    d: .oddddd;.xMd..,,:::::clx0Kx.:XWWWWWWWWWWO.,dddddddddddddddddddddddddddddddddddddddddddddddddddddddd; .lddddddddddddddddddddddoc    //
//    o. ;dddddd;.xMd.lOdlc::c;.;kKc.dWWWWWWWWWWWk.,dddddddddddddddddddddddddddddddddddddo;.;oddddddddddddd:. .:ddddddddddddddddddddddoc    //
//    :..cdddddd:.dMd.':cldk0XO,'x0;'0WWWWWWWWWWWk.,dddddddddddddddddddddddddddddddddddddoc,.':oddddddddddl..;.,ddddddddddddddddddddddoc    //
//    ' 'odddddd:.dWo'dKWWWWWWWl.lx.;XWWWWWWWWWWWO.'ddddddddddddddddddddddddddddddddddddddddo;..,coddddddl'.co'.lddddddddddddddddddddddl    //
//    ..lddddddd:.dWKKWWWWWWWWO'.;,:kNWWWWWWWWWWWO..odddddddddddddddddddddddddddddddddddddddddoc,.',;:::,.'cdd:.;ddddddddddddddddddddddl    //
//     'dddddddd:.,ddxxxkOO00x,.':oOXWWWWWWWWWWWWk.,dddddddddddddddddddddddddddddddddddddddddddddol:,''';codddo..cddddddddddddddddddddol    //
//     'ddddddddl,... ..........'...:kK00KNNNWWWWd.:ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd:.'odddddddddddddddddddoc    //
//                                                                                                                                          //
//                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BNZ is ERC721Creator {
    constructor() ERC721Creator("Ze Bankerz", "BNZ") {}
}
