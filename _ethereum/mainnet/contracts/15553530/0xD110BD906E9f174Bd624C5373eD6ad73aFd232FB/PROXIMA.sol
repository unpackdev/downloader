
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eashley North
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                    ..   .                      //
//                                                                                                        ...                     //
//                                                                                             ..          .                      //
//                                                                                           ;k0Oxxx,                             //
//                                                                                          'ONNNXXK:       ...                   //
//                                                                                          :XNXXXXd'                             //
//                                                  ...,,.                                  dNXXXNXk:.       .. .     .           //
//                            ;ooodxx,             :OKXNNKd;.                 .cddxkxd:    .xNXNNNNKdlcc:;,';oodOOkxxkOk:         //
//                 .',,,'.',',xXWWWMXc...,;,.:dxxdldKNXK0KNN0olddxxxOkc;cccccld0kdkxkKOoloc:kXNNNNW0oxXWNNNOoclkKNNNNNNNo         //
//               ,l:oOXWOlx0olKXNWWXkkOl;c0KxkkxKWXOxkKXKXNNx:lOKXWNX0dxKN0dlxKNKookxdOKK0o:oONNNNXO0NNNNNXkdooookKNWNNk.         //
//            .,oK0:dXX0;,xXOkKKXN0d:oOc,:xxOKKXXNWNd;oOXNWKcl0KOKWNkoc:oOKxcd0Kd..loxNWNNOoloOXNNKx0NNNNNx'.l0KOkO0XWNc          //
//            .lKWKll0XxoOK0kxoc:oddxkkllkl':,:oddddoox0KNXOOKXXNWWXdlo:;cddolcxklccOWWWWX0xdocdOKX0dx0NWXkl,;OKkkOOKXW0'         //
//             .cxkd,';;:;'.      .',''....    ..    ....,''colloollc:,.    ...',,..,cc:;'.     .';,..',;cc:':oox0K0K0o;.         //
//             cOxOKc             .'';;;'........  .;;,'','';'      ;dl::;..................','.....        .ccdXNNKKK:           //
//             ;O0xko.         ..;loolcc::::::::::::lolll:;;;.       ,o:......'',:ccccodxxoccc:cccllc:;,.    ;x0XXNNXXd.          //
//             .,:;xo   ..  ..,colc;'...     .,:cloldkdddc;,:'        ,:....,:clol:'....,lolcc:;..,odo:,c:.   ,okOXNKKk'          //
//               ;dx,   .';:lo:'.         ..   ....';c:,;ll,;c,'.     ...:lcccc;..        ..        .cdl;;,.  .lxxOkdolll;.       //
//               ;ol'  ,cll:,.         .,,,''. ..        .,;'.,;'.'....:l:'...    .''......           .:;',;'.:Oxlll:;:lOO,       //
//              .coc,',;:co;           'dx:...',;'         .,'.......,lx,        'oxl,....',.           ;o;.,:dOxooodxxxkk;       //
//              cOkd;;:',:dd:'         .oxc'...';'         .;'...   .ckOl.       .ckc.  .,,,.         'lodc,,cdkxx0Kxc:,..        //
//             'xKKO,;llxocldxl'       .'cd:'.''.          ;;'...';clloOOl.       'ox;..';,.         .odxd:lc'ckod0Xx.            //
//            .cOK0d.;xkKNk::lodl,.    .',,',:'           .c:'..cxx0Xxldkkl.      ';;,,::'.         .cdooxOd. ;O0OO0k,            //
//             .:Okc. ;dddkOkxloxdll:'.  .....           .ld:.';;..'xOxdo0Xd'      ...,'.     .':lolooolldl. .::;okc;c:.          //
//              .:xx, .cl:cdkOo:ccclooc:'.           ...;odc,''......oK0kOOxdc,...        ...,cllooc:;:c:c:. .'..co;':d:          //
//             ;l;oXd..:'..,clxkxkkdc::cc;,''''.. .'clldxo,';:c,'::' .dXOoldO0kl;,,'....,;;:llllcclo;.;,..:' ,c,:ddxOO0l          //
//             :O0XNd..c'    .;do::llll'.;ol:cloocll::cdxc.,lc:;.,c.  ,xddxxk0xc:::cl:;:oxdoolc:;lo,.,ll'.:; .ckkxxOOk0o.         //
//             .:xO0: .l:. .',,,.'''.:l;'lxc;:lllc::clol;'.,:,,c;... .,c:coooddlcl::oo;',clccc;,,'....'lc.'c' .dkldOOO0x,.        //
//              .oxc.  .,','. ..........','',;;,...''.....,,'''',,',,,;.';,;,',,,ll::lllcc:;'........ .;l;.''.,kkOKOxxxolc.       //
//              .dkl. ...,.      .. ......  .......,......''.............. .. ...;;;;:c:,,'.. .',,'.  .:ol, ..ckxOXK00Oxdx:       //
//          .:ldOKkl,  .;;.  ....     ...   ..........,,'....... .......         .'.........''..      ,lllc...;xk0KKOolooo'       //
//          'xXXX0kd'  ,c;.;::c;:;;:o:.        .;c:. .'..       .:lllo:......',:oOKd'.:oxo:lkKKklclxd,:dl::;..cllox0K0xl;.        //
//           .llcd0O, ,cc,,lddo:,:xO0x,   .';,:kXXOoc;',;;..,,'ckOOdcdl..cddxxolxkxkdxxdOKklcxKXNXKXkcloc:c; .ddcoldOx'           //
//            ;lldOd..clc,':looocooclodc,;lxxlxK0d:;,',cddc;;coO0o:''o:'lxdccl;cxc:OKo':OKOOl,coOkllccoll:c' ;K0oodk0O:           //
//             ,O0Oo..ccc:lccoocoo;ck0klcll::cxKxlc:,..,odc,,;;dO:..,,'oOkl'',,co,,xOoco0klo;.,:xx;,;collll'.lKkooxO0KKd:,        //
//             ,kkxx;'cc:c;,lc,cdl';kXkcloc:l:;ol;;c:,.'oxl::c:ld,.,c;'lOkc..';:oc,cxooxkOo;;:codxd:;lxxdxo,'k0oodk0XNN0kc.       //
//              .'lOl,ll;:;,c:;ll:.,x0lcoc:cll;cdl:::;,,ldl;'',cc;;odc:cdc...,;lo,.',,,:lxxoolcc;ldc;dkdloo'.oK0OO000XNxl;        //
//              ,okd,,do:;lccc;::;:okx:;lllc,,,:xoc:,',;cl:....,,..,l:;;;:cloolc;:dl,;:,';clc:;,;cc;;ddc:dd;..x0dx0NXNNX0c        //
//          ,ccoodd;.:xo;':c:c:;cooodo:;coolcc:coo:'',,,;;::;:l:,;c:;cl:ll'.. ,codxd:cdxdl;;;,,,,;;;;oocoxdl'.oKxkXWWWWKOl        //
//         ;0XXXxlldccxdc,'cxl'.:xkxkkc,lk0xc,,;okd,'.  ..cdc..,;ll;.,ol;..';,;cc';lccc:ooco:.,:::lc:lol::lx:.lOdx0X00Kkd:        //
//         .xXXKKxdOl:xko;.cxd,.;ok00kl;cokd:.';coo;'..';;:dc.';;:::,;do:,'cdddo;,cc:lc;:llc,.';loocloc:;cdkd,lOxdk00Ox'          //
//          .ckOOOkd:;xOd;.'ol;,,,oOOx::c:xko:;,,,lo,.colc:o:.,cc;.',c:':oc,,lc:ccc;;ldlcdxo;'';ccccooo:;lddl':00Ok00o.           //
//           ,l:ckdcclkOOd..ld:,.'coxxc::lOc,:;c:'':::lcclcoc,clc,.'''.,:clc::,,cc;'lOkoooxkd;.,colloolcoxdd:.cXXKkxl.            //
//           lOdoOkccx0ko;..:kkl..:::ooc,ckl;;;xx:'';cllc:,;:cl:...,;':xl,;cc:.,ol;;oolcllokxo,':lcoxlcc:cdl..dWWNOo;.            //
//           .::l00l:oOd:...:xxl..'c;.,c;.;ollxkl,..;clOxc,.':ol,..':dxko,',:c,,lo:;lxo:ldkxdo'.,::odc;colo:.'OWWWXOxdc,,.        //
//             .:dddlcddc'. ;xo. .,cc..;o;.,;oxxl.  ,lckkl:..lxo,...,lxd'.:lcc;.;oo:'ld:oOdoo;. ,cclcc::ccd; ,xkOOkxkOkdd;        //
//              ;clOd;okkdc..oc.,:;lx;..ok:':okkd:..:;cdxo,.,oOd'.. .,ol,okd;,;,cc:l,,dlckl:c,.'cooll:,;clc, .;lxkk0KKO0O,        //
//            .,ldk0o,oO0O0k:c:,ldkkx:..'oOl:oxxxl,,:::;ld,.ck0Kl. .. ;l:cc,,,;co:;d;'xk;;:;:,;dxlclc'.;od;...'lxk0XNX0Ok;        //
//         .okOOdxNXl'lxOkO0xlc:oxdocc;,;cc;,clloc,;ccccclc,:xOOx:'''.,:;;:;colccccdoldl:c;::;:;;,;cc::dxo:,;.'dkkkxccc:l;        //
//         .,,..;dOx:;ccooodl::;ccclc:,:oc:lc:cc::;,okkOOxc;codooolc;,::':xddkd:,;cl:;:looc;::;;;::;:cclclllc:xOOkkl. .           //
//              .lxlcokxo:;:c;;lllolc'.;kOocccclool;oKXKko;':docclcc:;:c:ldc,'';::;:c;;:cc;::,';;;,;cccllllolcxOkOKOlc:lc.        //
//            .;lOK0ddOOkxxddlcdkxol;;lloKN0kko;lOkccOKOkOko,;ooc:::;,ldood:. ..,::lxdc::;,lxc'....,:,.;odkxd::dkOKXkdx0l.        //
//           'lclKWXxdOkdkKKkdcoO0xdkOKxoKXOl;,'';cldddOKWNx':kd,....'..,:clc,'';:cooccc;;;:oOx;,;;;'..lxOxxd',kOO0XXOkl.         //
//           lOxkOX0l:okO0kl;::;o00OOOOdoxx;.,lc;,,::,'';cl;,cl;.    . .,,',clcc::ll;',,;;,'',lxxddolcodoldx, ;dxO000Okxc'.       //
//           .:xkdOO;''.';:;;;,';coc:::;',,',;,;;',,;;,'''''...,.. ...';'.''..,,';;,''',;,'.'...;cdxdlc;':o, .cokKK0kxdkkx:       //
//             .:xXNl.....'',,,'..........'..',;,'''',;'';'. ........';.....'..'.... ..........  ........'.  ,x0KKKKOkO00O,       //
//            .ckkKNx... .........       .... .....'..'....  .'.''...',.....,'...     .''.,,......  .......  'dkO0KXKOxxkc.       //
//            .dk;oKc.....  .. ....        ......  ...'....  ...'',;;',.     ...      .'........   ....'...  .;odxO00Kd..         //
//             .:ldO, ...   ..            ... ............  .. ....',...      ...  . ....             ... ..  'oOXXXNNK:          //
//              'lk0:  .                  .        .            .....           .  .    ..                    ;kOK0Okxdl;.        //
//          .cddOkll:.''........    .................     ................    ....''.'''........  ...''','.''.lKKK0dlccloc.       //
//           lXNXklldO0koo00olxxddxkOdokkcodlo0kodlcooc:;,:oco0koccldOxlxOx:''o0xxX0kKkodod00kOOxxOxcckNNKOKXkox0KKK0OkkKd.       //
//           ,0NX0clXXO0O0NXxldk00XWO,'okld0k0NKkl,;llckx:lxld0l;c:;'ck0XNNO:oXK0XNKKKdlc::oOOoodxxc.'kNN00Nk;,;okOO0KKKXo        //
//            ,ldo:lOdl:cON0kKXK0dxN0dcoOOOl,xNN0doldxxxdc:d000kK0dc:xKKKklodONKxk0XNXKx'';;codooooxxkXNK0NNo'..;lcdl'.''.        //
//                ...,ooxX0kOOO00kkKNXK0K0l,':kNXx;,;oxdc..,cxdodO0OKNNNKc  :0NXl'xXxod:...  ,ddOKOold0NKKNN0ol;,cldl.            //
//                   .;::;..',:dKXOO0Od,';lxkkxkx,     ..  .;o; .ckO0KXXo.   'cl, ;OOdc,    ;o,.'oKc.':ookNNKxdl:;;'.             //
//                           .cxdc,ol.     ....                    .....           ..;c:.  .o: .;xK:     .,,....                  //
//                           :ko,coOd.                                                      .....':.                              //
//                           ,clkkxdo.                                                                                            //
//                              .                                                                                                 //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PROXIMA is ERC721Creator {
    constructor() ERC721Creator("Eashley North", "PROXIMA") {}
}
