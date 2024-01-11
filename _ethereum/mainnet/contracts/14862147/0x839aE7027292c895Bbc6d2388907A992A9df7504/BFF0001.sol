
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Last Lightbender 0001
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                      . .   .                                                                                                   //
//                                              .. .=I=??=+?$?7I+~~~. ..                                                          //
//                                        ..??++I7$Z$7ZOIZ$$7Z8$$ZZOZZ?=~.                                                        //
//                                     ,IZODZZZ8OO8888$Z8ODDOOOZ78OOOO8OOOO$$=I~,                                                 //
//                                   IZNZZN$OO$N8ZZ8ONO$OM88D8ZO7ZDNDODZ8DDND88DO8??..  . ..                                      //
//                                . ?$OZ7D8O$8O8888D$8ODOZZ8OO88ODZO8ZD8OOZOZ8OOOZ8=ZIZ~,.,,,..                                   //
//                                ,O$ZZZO8MZ8ODNDDODN8MD8N8Z888OO88MO8OZZO$O$ZZZZOZI$7I$ZZ$Z7$I$=,.                               //
//                               ?DZOOO$DNDMZ8NOD8DD8Z8N$8D8DDOD8DDZ887ZO$ZZZ8$OZOZZ$ZZZO$Z77$$$77I?:... .                        //
//                              ,$8I$$$8DZODOODO8OD8DDMODDZZDOOON8OOZZZ8$ZOZ8ZOZ$$$OO$88ZZO78$ZZZ$$77$$O7:...                     //
//                              +8NZNDD8NOONN8OZD8DDM8DDON8OOOD8OZOOZZZ$ZO8OZ$ZDZOZ8ZZD8$88DOOO$OOOZZZ$7$ZZ$+.                    //
//                           . ,$O8+ND7$MNNZDD8O8NMMN88NOD$Z$ZDODO$Z8Z$DOOO$OZOZZZO8ZZ8D8ONND88ZNOZOZ$Z77OZ78I,,                  //
//                ..    ...:..:?7DI8ZZM$88ZNONOZDNNDDODNNOZ8$Z8DZO8Z$OZOZO$OOZZ8OO8OOOZO88DND8DOODN$D8$$7ZOO D8. .                //
//                ,,.,.?+I+~O+:++:IIO7Z78OI=DDODNNNDO8$8888DOOZ8OZZZODO8888ZO88DZDDOO8O$8ND888OOO888ODNO8Z8Z7=D8~                 //
//                .I$ZZIZ$D=O+7OOI:?Z8N7Z7+Z8DOZDZNDOD8Z8DMD8OZ8O7O7ZZ8OOZZ8OOD8ODDOZZOO8ODNMNODO8N8MONDDZZ8Z~D8?                 //
//                ,ZI77?ZOZO8MZ$+M$=?$ZZ?ZNZZ7NMD?D8D8DDNN8D88ODDZZ$$Z8Z8NZDMOM88N8ONO8DDNDDDD88ODO8N8OOODO8+?D8$:                //
//                ,Z$DIZNONZINMZZ7OO+~:Z8?$O$MNNDODZ8DN8DD8ND8$8DO8OOZODODNNMDND8DMDNDNDDOMMNMNMDOOD8DN888DD=888Z:                //
//                7OD+D877$OIM$?OO8NO7=ZDOIZO8NOZZ$D8DNNNDDDD8ZDO8D88D8N88N8D8NDN8NNND8Z88DDODD8OZDDNNO8DDDO,D88,.                //
//                7O7ZZ?7O$ZDZZ7$7NNOOZZMNNDMDOZ7ID$D8I?DD$O$OZMDZ8ODD8MD8D88DMMMNDNMODOO888DDND8DD8ON8DO888OND?,                 //
//                ?DODD88N87NDZ$MODNO8D8IZ88MNN8+,=M8 Z7I8DDDOON8DOZ88D8NN88NOMND88NNNN88O8DDDDDDNO8ONDD8DO8DNN+.                 //
//                ?7ZN8888ON8NMNNDNNNNNDZZO77DN~.~8I,I8ZOOO8OONN$NN8N8D8DDNONN8MNNDDD88888DDNNDDDDDO8NDDDOOD8=.8..                //
//                ?ZO88ZMDNDDDDNMMDDD8NN8D8$7D77=DD+$DZNOOZNN8DD8NDD78D$ZODDD8DNDDD8D8DDDD88DNDDNODDD88D888O8+Z7I                 //
//                ~$NN78DNDNNDDMNNDD8NNDDMDNMM$7ZI==ONZNO$ZDNNDZDNNMNDD88NDDDDDDDDD8N8DN88DMDD888DDNN8D8DO8OO:++                  //
//                =D88ODNNN8D8N8DNDN8DNNNDNON87Z+O8OZNN8MZO8DDDDDDDDDD8O$DNDDD8DNN8DD8N8DO8D~DDD88DD888888OOOZ?,                  //
//                ~$DN88DDODO88DD88N8DMDMODNN88$DNZ7O8DNDIIZ7888DDNDNDDDNNNON8DDDNDDODO8OD. .~D88888D88DO8OOZOD$7.                //
//                =OODD7888DODDO8D8DODNDNNDNNMMMNN7DDDDDN?8DOOOOO88DNDDDDDDDD8DD8DDN8888..   .=8D88O8D8ODD88O$ZDOZ                //
//                 ZO8DO$D88OOZ8ZDDNZ$NONNNNNNO+DDI8DDODNND8Z8DDDNNDDD88DD88DO8DDO8O8:       . +D8DDOD8+=O88OO7$$?O               //
//                 IDDNNNNDN8DONDM8NDO888MNNND$DO88ZN8DDODD8DDDDNDD88+= OI+D8,.8N8DO.          Z888ODD8+..,~888OOZZ               //
//                  ,888OND88D88D88OO8NO8OD8NZ$N8O8NOD8ZONO8NDDDDD$:Z..         , $             +88D88DO8.   ~O88OO~              //
//                  .Z8DZO7?NODDN$8OOZ8O87DNOD8DODOIZZOZDDDODD88N88~             .              :8888OOOZ     .OO8ZD.             //
//                   .$8O88OZDD8D88,..:D.+,ZD8$ODZ8DZOOD$888DD888D8+                            .$88O8ZO~       O8OO,             //
//                       =O?D88Z8? ..:,::.Z8ODZZ8IZ$O8DDO88DD888DZ$+.                             OOO$O:        ,OZOO:            //
//                         ==?Z$O7:      Z$ZZO$8O77. 7.D=$7,8ZOO8ZZ+                             :ZZ88?.         ?OO8?            //
//                         .$7ZOZ      ..$O8DZZOZ        .  .ZOOOZ$.                             =7788..          ZOO8.           //
//                          :8Z?O.      .=OD88I .           .:O$8O7                              ZZO8:            ?OOD$.          //
//                           .77D.      $8OO7.                ZOZ~                            .~=OO8Z.             888I           //
//                               .    .8I78:                 .ZOOO,                           .~Z8OZ:.             ~8O.,          //
//                                   =Z$ID8.                 :$Z8Z~                           Z7ZOO.               +Z$O.          //
//                                  =~$O7O7.                =O$$8=                        .:II$ZZO.                :I,:.          //
//                                .,?I+=+?.               .:~:,:~..                     . .+~7??I?.                               //
//                                 ~~?77..                ..7:+,..                      ~,,=,   ..                                //
//                                                           .:                                                                   //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                     ~.               ~. .          . .=.. .           ..=.                                     //
//                                  NMMMMMM.        .MMMMMMM.         MMMMMMM.        NMMMMM                                      //
//                                 MMM, ,?MM       .MMM ..NMM       .MMM  .MMM.       +O ,MM                                      //
//                                .MM     MMM      .MM    ,MMN       MM.    MMN           MM                                      //
//                                MMM     ,MM      MMM     ,MM      MMM     MMM.          MM                                      //
//                                MMM.    .MM      MMM.     MM      MMM.    :MM           MM                                      //
//                                MMM.     MM     .MMM      MM.     MMM     .MM.          MM                                      //
//                                MMM      MM.     MMM     .MM      MMM     7MM.          MM                                      //
//                                NMM     MMM      MMM.    MMM      MMM.    MMM           MM                                      //
//                                .MMM    MMZ      .MMN    MM.       MMN   .MM .          MM                                      //
//                                  MMM+MMMM        ,MMM+MMMM.       .MMM=MMMM        NMMMMMMMMM.                                 //
//                                   OMMMM.           DMMMM.           OMMMM..        DMMMMMMMMZ,                                 //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BFF0001 is ERC721Creator {
    constructor() ERC721Creator("The Last Lightbender 0001", "BFF0001") {}
}
