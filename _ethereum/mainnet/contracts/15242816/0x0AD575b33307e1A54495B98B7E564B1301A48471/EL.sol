
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EloiseLavinie
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                        //
//                                                                                                                                                        //
//                                                                  ,--,                                                                                  //
//                                                               ,---.'|                                                                                  //
//        ,---,.  ,--,                                           |   | :                                                                                  //
//      ,'  .' |,--.'|              ,--,                         :   : |                         ,--,                 ,--,                                //
//    ,---.'   ||  | :     ,---.  ,--.'|                         |   ' :                       ,--.'|         ,---, ,--.'|                                //
//    |   |   .':  : '    '   ,'\ |  |,      .--.--.             ;   ; '                  .---.|  |,      ,-+-. /  ||  |,                                 //
//    :   :  |-,|  ' |   /   /   |`--'_     /  /    '     ,---.  '   | |__   ,--.--.    /.  ./|`--'_     ,--.'|'   |`--'_       ,---.                     //
//    :   |  ;/|'  | |  .   ; ,. :,' ,'|   |  :  /`./    /     \ |   | :.'| /       \ .-' . ' |,' ,'|   |   |  ,"' |,' ,'|     /     \                    //
//    |   :   .'|  | :  '   | |: :'  | |   |  :  ;_     /    /  |'   :    ;.--.  .-. /___/ \: |'  | |   |   | /  | |'  | |    /    /  |                   //
//    |   |  |-,'  : |__'   | .; :|  | :    \  \    `. .    ' / ||   |  ./  \__\/: . .   \  ' .|  | :   |   | |  | ||  | :   .    ' / |                   //
//    '   :  ;/||  | '.'|   :    |'  : |__   `----.   \'   ;   /|;   : ;    ," .--.; |\   \   ''  : |__ |   | |  |/ '  : |__ '   ;   /|                   //
//    |   |    \;  :    ;\   \  / |  | '.'| /  /`--'  /'   |  / ||   ,/    /  /  ,.  | \   \   |  | '.'||   | |--'  |  | '.'|'   |  / |                   //
//    |   :   .'|  ,   /  `----'  ;  :    ;'--'.     / |   :    |'---'    ;  :   .'   \ \   \ |;  :    ;|   |/      ;  :    ;|   :    |                   //
//    |   | ,'   ---`-'           |  ,   /   `--'---'   \   \  /          |  ,     .-./  '---" |  ,   / '---'       |  ,   /  \   \  /                    //
//    `----'                       ---`-'                `----'            `--`---'             ---`-'               ---`-'    `----'                     //
//                                                                                                                                                        //
//          .....                               °OOOOOOo *O° oO.                              °***oooooOOooOOOOOOOOooOOOOoooOOOOooOOOOOOo °               //
//        ....              ......      .°°****.oOOOOOO.°OO..Oo                            .*OOo**°°....    .°*oOOooooooooo****ooooooOOOOo.°              //
//      .°...             °oo**********oo**°°.°ooOOOOO°.OOo.OO°                    .°*ooooOO*°                  .°°°°°°...........°*oooOOO*°              //
//     .° ..            .*o*.        ..     ......°oO*.OOOoOO*                  *oOOOo*°°°.. ...°°°°..°°°.°..      ..  °*ooo*****°°..°oooOo°.             //
//    °°  °         °**ooo*     °****°°°°****°°°°°..*.oOOOOOo                 °OO*°°°.°............         .°°.       ..°oO*.°******°.*ooO°              //
//    .  .        .oooo**.    °oOo°.              °°°oOOOOOo.                °Oo°°*°...  .                    .°°°..       .oO.*OOOo***.*oOo.             //
//                *oo*       *OoO°                 .°°oOOOo.                .OOoo°.°°*ooOOOooo*°°°°****ooOoo°    ..°°.       oO°oO*°oo**.*Oo.             //
//                *oO.      oOoOO  .***°°°.         °° oOo                  oOoO*°OOOOoooooOOOOOOOOOOOOOOooOOOo°°..  .....   °OOOo ..°O*o°oO°             //
//                *oO     °oOoOOo.***OOoOOOOo*°.     ° °O°                  oOOOOOO°.       ...°°°°.....    .°*oOoooo*°°..°°. oOO*.OO°°O***O*             //
//               *oO*   °oOOOOo*°..*ooooooooooOO*    ° .O°                  *OoOOo.                                .°oOOO° .**oOo*°OOO°*o**Oo             //
//      .       *oO*  .°*OOo*.  .°*oo*.  °ooo*ooO.   °  o*                  .OooO*                             ..    ..°°° .°oOOooOOOOo°o**oo.            //
//     .       °oOO..*. °o°   °oOoo**. °ooOOOOOOo    °  o*                   *OoOo    °*°.                   °o*      °oooooOOOOOOo °O**o**Oo.            //
//    °       .ooOo**. °°    °ooo*°oo  Oo°. .°*°    °. .O°                   .OooO°   OOOo°                 .*.     .*oOOOOOo****°   O**o*oOo             //
//    .       .ooooOo*°     .**°o*oOO° *°  ..      °°  oo                    .OOOOO.  *OOOOo**°°     ..              °oo*..         .O*ooooOo             //
//            °oooOOo.        .****ooOoo° .oo***..°.  *o.                   .oOOOOOo   .**oooo*oo**.  .         .°°°°°°°.           *O°ooOoOo             //
//           °ooOOO*.           °o*.ooOOo. **  .°.   °o°                   °OOOOOOOOo***°**ooo*****oo°   °°...°**.*oOOoooo**°.     .Oo*ooOooO.            //
//          *oOOo°.              .. *oOOoo. O*       *°                   °OOOOOOOOOOOoooooooooOoOo*****..OO***. .oooo***oOOoO*    .o*°o*oooOo.           //
//         °Oo*.                    .*OOOOo..o °.   .o                    °OOOoo***°°.           .*Oo**°o*.o*        °OOo*oo°*O*    °***ooOOooO           //
//         °Oo°                       °oOoOo.*.*O.  °*                     °.                      .*Oo* *o*Oo°.    *O*o.     °oo.   .***oooOoo           //
//          *Oo.                       °ooOo.*°oO°  *.                                               °*o° *OO*      *Oo**.o*°..ooo*    °°*ooooo           //
//           *oo°                       *OO**OOoo  *°                              ..°°°°.             °o° °OO.      .oO°***.o**oooo.   ..*oooo           //
//            .ooo°                     °Ooo*o°o  *°                            .*ooooo**oo°            .*o.°O*        Oo*°*°oOO**ooo*.  ..°ooo           //
//             .*oo°                    °O**o*oo o°                           .*OOoo*°*oo**oO°           .oO*oo.   .°°.*Oo*.*°oOOoooooo*.   .*o           //
//              °*°*             °**.   .O* ooo*.o                        .°*oo**°. .°oOOOO*oO°           °OOOo. .oooOOoOOO* °° .oooooooo*.   °           //
//               *oo.           .OOOO°   oo .o. *o.                     .oOo°   .°*ooOoooooO°oO°         .°OOOO. o*°oo*oooOOo.°*°°*°*ooooo*°.             //
//                °o*            *OOOO.  .O* .o***°                   .oOOOO*.°oOOOooOOOOOoOo°OO°        °oOOOO  ooo. ..°**ooOoooooo..°ooo**o°            //
//                 °°             ..°O*   oO. °oO*°.               .°oOOOOOOoOooooooo****oOOO*oOo.     .*oOOoo* .O* .ooo****oooo*°**o° .*OOo*o*           //
//    .            .*                .o   oO. °ooO**            .*ooOOOOOOOOOOOoooOoooooo°*OOo*O*o**°**oOo*..o° *o.°o°       .°*o*°°°°   .*OOoO           //
//    o.                              *.  oO. oo*OO°          .oOOOOOOOOOOOOoooooooooOOoOo.OOoooo°oOOOOo*°.*OOOoo*oo  .°°°°°°.  .*o***. °.°oO.°           //
//    .*                              °.  oO° *°°Oo.        .*OOooOOOOOoooo*ooo*°°°°oOOOOooo*oo°Oo*oo*°°°*oO°.**OOO°°OOooOoo*oOo° .oooO***ooo*.           //
//     °°                             ..  *Oo °*.O*        °oOo* °Ooooo**ooOOOo**°*oooo*****oo.oOOOOo**oOOOo**o*°*.*O°..°*oo°°°oOo  oooo*°  °oo           //
//     °o                      ....°*°.°  °OO. o*o*    ..°°*oo°.°****oooOOOO*.  .......*ooo*. oOOOOooooO*oOOOo.   °o.*o***oo*.  *Oo .OOoo*.  ..           //
//    .*O°                    °°**°..o*o   oOo o**Oo*°°..*oOoo.°ooooOOOOOOOo°°***°°°°..°°**°°**oooooOOOo****.    *OooOOOooOOOOo°*oO° °Ooo**               //
//    . oo.                  °**...*° *Oo  °OO°*ooO*. .°oOOoOo°Oo**oOOooOOoOOOO*..°oOOo**°....   ...°*oo**°°°°.*oOOOOOOOOOOOOOOOOoOO° .Oo**° °°           //
//      oo°                  **     *. .oo  oOo*oOO*.oOOooOOo°O*°OOOOOOooOOo*.  .ooOoOOOOOOo****°.  ..°****OooOOOOOOOOoOOOOOOOOoOOOOO° .O*oo °O           //
//      o**                  **      *. .O* °OO*oOOooOo*°oOo.oo.OOOOOOOOOo°    °Ooo° °oOOooOOOOOOOOoOo°.   .°oOOooooOOOOOOooOOoOo*OoOO. *o*O° .           //
//      oO*.                 *°      .o.°o*  oOo*OOOO*.*°*O*.O°*OOOOOOO*.   °ooOOoo   .*****ooOOOOOOOOOo*oooOOOooOOoooooOOo.oOOOO*oooOo  o*O*             //
//      oO*°                 °°       °ooo°  *OoOooOo*oOooO°°O.oOOOOOO*    oOOOOOOo .oooo**°°°°*oOOOOOOOOOOOo*°..°..°o*OooO °OOOOooooOO° *oOo             //
//      oOO**.               °.        °*oo  .OoOOOoooOooOo oo°OOOoOOOo°..oOOOOOOOOooOo*ooOOOOo*°.°°°°°°°°..      .*OOOoooO.°OooOooOOOO° .oO*             //
//      °OOOOOo°            °°           .o*  OOOOOOooooO* *O*°OOOOOOOOOOOOOOOOOOOOOOooOooooooooOo*°°°°°.       .*oOOOooOOo °°*oOoooOOO.  *o* °           //
//       °oOOOOO*          .°.  .         .O. *OoOOOooOOo °OO°*OOOOOOOOOOOOOOOOOOOOOOOoOoOOOO*o**OOOOo*°.      *oOOOOOoOo°  .*ooOoooOOo   °***o           //
//         °oOOOO*         .°  .Oo.        °*  oO*oOOOOo.°*OO.oOOOOOOOOOOOOOOOOOOOoooooOoOOOOOoo°*oOO*        .ooOOOOOOo    .ooOOooOoO°  ***°oO           //
//           °oOOO*        °°  °oooo°       o. °OooOOOo.*O°OO.oOOOOOOOOOOOOOOOOOOooOo*oOOOoooOOoo***ooooo*°    .*oOOOOO..ooooooOooooO*  *o°o°oo           //
//    .        °OOO.       *.  °Oo°.o     ...°  *OOooo*OO*oOo°OOOOOOOoOOOOOOOOOOooOOOOOOO°....°oOOoo°°..°OOO°   .oOOoOo.o*o**oOOooOO°  °O*o°*o*           //
//    °.        °OO*       *   *o.  *.     O**°  oOOooOo*oOOoOOOOOOOOoOOOOOOOOOOooOOOOOO*.°°*o*.°oOO° .*oOOOO*.  °oOOoOoOo*oooOo*OO°  .O*°O°*oo           //
//    .°°.       *Oo       °. .O.   *°     *Oo.. .**ooo*OOOOOOOOOOOOooOOOOOOOOOO*oOOOOO*°ooOOO°o. °oO°°......°oo*  *OOOOOoooooO*oO°   *O.°O°ooo           //
//      .°°       oO.      °° .o    °*  °****°.*.   *o*oOOOOOOoOOOOOOOOOOOOOOOOo*OOOOOo*OOOOOO*o*  o*     ...  OO. *OOOOooooOO*oO*    O* oo.ooo           //
//        .°      *O*      °.  **    *°°o..°°*oOO*  *o*oOOOOOOoOOOOOOOOOOOOOOO**OOOOOOoOOOOOOOO*°. **°°°.....**o. .oOoOO°oooO**Oo    °O °o*°O*°           //
//    ..   .°     .Oo      .°   o.    *o.    °oOoO. *°*OOOOOOOOOOoooOOOOooooo*oOOOOOOoOOOOOOOOOOooo***o*°.°  .O°  *OOoOO°oo*O*oO.    o* *O *o*°           //
//    °°°.  ..     °Oo     .°.  *o          .O*°OO°°°°OOOOOOOOOOOOoOoO****°°*oOOoOOOO*OOo*°°°**oOo°*ooOOO.°. *o  .oOOOoO°*OoO*O*    .O°.O° o**            //
//     ..°  .°.     °O*     ..   o°         *Oo *Oo°*oOOOOOOOOOOOOOoO° oOo°*oooooOOOooO*.    .°.°o°°*o*oOo°° *o  °OOOOoO°*O*o*O*    °o.°O°°°o*            //
//       .°  °°      °O*     °.   o.         oO. *OooooOooOOOOOOOOOo#*  .°*°°°°*OOOO*O*.       ..oo.*°. oOo° .o  *OOOOoo°*O*o*O°    *o *O**.o°            //
//        ..  .°.     .O*     °   .o          O°  .°oOoOo°OOOOOoOOooo..       *OOOo*o*. .**.    *O* *oO.°OO°. o. *OOOOoo°oO*o*O°    *o.°O°*.**            //
//         .°  .°.     .O*     °   °o.        .*    °Oooo**OOOOOOo*o  .      oOOOooO*.  *°.*   .o*  °°*°°OO*° o° °OOOOoO**O*o*O*   .Oo°.o*°.°*            //
//           °.  ..     °O*    °.   .°°.       .*    OooO*o*oOo*.°°        .oOOOooOo.  *O°.*   *°     *.*OO°° °o °OOOOOOo°O***Oo    oO**°o.. *.           //
//            °°. ..     *O*    *      °°.       °   *ooOooO°.             oOOOooOo.  °Oo.°. .*      °* OOO°*. O.°oOOOoOO*oo*°OO°   °O*o*o*. °*           //
//             °°.  .     *OO*°°oo       °°        .o*°oOOoo#*            *OOOOoOo. °*.o*.*  °*      o.°OOo.*  o*.oOOOoOO*oo*°OOo   .Ooo**o. °o           //
//              °°°  .     .*ooOo*         °°      .**oOOOOoo°         .°oOOO*oOO° .*.°o* *.  .*°    o.*Oo°*. °o°°OOOoOOo°Oo**OOO.  *oO°°°o° .o           //
//              .°.°  .                     .°      .*OOOOOOoo*°°°°°°°*OOOOO°*OO° .*  .oo. *   .O°   o.oo**. °o°°oOOoooOo°Oo*°OoO. .OO*...o*°.o           //
//                °°.                        .°.     *OoOooOOOOooooooOOOOOo.*OO*  .   .oo. °  .*Oo°.*°*Oo* .oo°°oOOOOooO°°Ooo°oOO° °oO°..°o*o*o           //
//                 .°°.                        .°    .oOooOooOOOOOOOooOoOo..OOo.      °O° °  .°*OOO*°oOo. °O*.oOOOOOOoO°.Oooo*oOO° °oo*.°*o*Ooo           //
//           ....   .°°..   .                   .°.    *oOooooOOOOOOOOOOo. °OO*      .oo.°.  *.*OO**oO°  *O*.oOOOOO**oo oOoOooOoO. *oO*.°oooOoo           //
//           °°°°°°....°°.                        ..    .*..OoOOOOOOOOO*   oO*       oO°°.  °o oO°*oo. °Oo° oOOOOO*°oO..OoOOoOoo* .ooO°.°Ooooo*           //
//           .°..........°°.                        ..    .°OOOOOOOo*°    *O°       °**.°  °O° . .o*. oO. .oOOOOOo ooo .OOOoooOO.oOoO°° *o***o.           //
//           .°............°°....                    .°     °*oooo°  ..°°**.       .**°°  °Oo ..*o*° ** .**oOOOOO.°Ooo .oOOoo*OOOOooo°. ***oo°            //
//           .°........................                °.    .°.°°.°°°..           *°o°. .oOo*oo*** °° °o..OOOOO°.oo*o  oOooOooOOOoo*° °o*ooo.            //
//            °...........                              .°.   .....        .°*.   °**o°  °°*.  .°° °° °*  oOOOO° oO*o° .oOoOOOooOooo*..oO****             //
//            .°.............                             .°°.          ..°°**   °o oo.  °  .**°..°. °°  oOOOO° *Oo*.  °OOOOOoOOOOoo* °Oo°.O°             //
//            °.........°.  ..                              ..°°°°°°°°°°.  .o   °*.°°   °° °O° .°° .***oOOOOo. oOoo.  °OOOOOOOOOOOoo* oOo°°o..            //
//           .°............                                               .°  °**°°.  .°°  o..°°.°***oOOOOO*.°oo*o°  .oOOOooOOoOo.*oo.oOo°°.°             //
//           .°°°°°.......°.                                            .°. .*o°.  . ..  .oo**°*oOooOOOOOo°.oO*°°.  °oOOOOOOOOo. °***.°OO°  °             //
//               ..°......°.  ....°.          .oo*°°°..          .....°.  .*o*.  .. °*ooOOooooOOOOOOOOo*°.*Oo°.  .*oooOOOOOo*O°°***o.*.oO*  °             //
//                 .°........°°°...°. ....     °oo  ..°°°°°°°.......    .*o*.  *o°**o*o****ooOOOOOOO*.  °ooo°  *Oo*°*oOOOOO*°*o*°**°°*.Oo°  °.            //
//                  °.......°.......°°°..    .°°oo°                   .***°  °OOoOOOooo**ooOOOOOOo*.  °OOOo.  oO*..oOOOOOOOOOo****°**°oo.   °             //
//                  .°...............°.    **°..               .°****oo°°.  .oooOOOOOOOOOOooo*°..    *OOo°   *O°*°*Oooooo*°°**oo*oo*°°.                   //
//                  .°...............°    *°      ....°°°°°°°*oo******°.        *ooo°.....          *Oo.  .°oO°.°*ooooo****°°*ooo°.       .   .           //
//                   °...............°   °*     ....   ..°°**°°°°.    .                            **.  °oooo*°*oo*ooo*o****oo°.        .......           //
//                   ................°.  *.   ..     ........°**.  ..°°                   .... ....   .oOOooooo*o..**oooooo*.        ...   .              //
//                   .°..............°. .*   ..    .°.  .°****.  .°..                               .*OOOOOooooo*oo*°°.  .      .....                     //
//                    .°.............°. °°   °    °°  .*OO*.  .*°.                 °°  ..........°°oOOOOOooooOOoOo.             .            .°           //
//                                                                                                                                                        //
//                                                                                                                                                        //
//                                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract EL is ERC721Creator {
    constructor() ERC721Creator("EloiseLavinie", "EL") {}
}
