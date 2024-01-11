
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Vitaminisation
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                       ...',,'.                                 //
//                                                          .,.                      ...:ok0XNNXk:.                               //
//                                                   ..'.   ;d;       ...,,..     ...,o0NNK0XWMMMNo.                              //
//                                  .';'.         ..:xKXd. ....     ..;xKXXO:......'oKWMKl'';OWMMMK,                              //
//                                 'xXWXc.      ..:kNWWKc..'oxl'.....;0MMMMMO'....;OWWWW0,...:XMMMO'                              //
//                                 :XWWMd.     .,kNMWNk;...,OWWO,....lNMMMMMk...'oXWNKOxc....:XMW0;                               //
//                                 .;kNM0;..  ..;KMWNx......cNMNo....lNMMWWXl...,oxo:'......:0WWx'.                               //
//                                   .dWMK:......oNMK:.....:OWWO,....cXMMWKc..;dOx,.......,dXMMK;..                               //
//                                   .cNMWd.....;OWMNc....lXMNk,....:OWMMWOclkXWNx,;lxOOO0XWMMMWO:..                              //
//                                   .dWMWo...:kNWWWO,...:KMWx''cxk0NMMWWWWWNXOd::xXNKOOXWMMMMMMMNk,.                             //
//                                   .dWMMk'.lXWWN0l'....dWMX:.:ONWWMWWXkolc:,..;0MNo'..oNMMMMMMMMMK:.                            //
//                                    .oXMWOxXWNOc......cKWWx'...cxKMWO;........xWWk'.'oKWNXXNWWWWWNl.                            //
//                                     .;OWMMMWx'.....;xNWKo'...,xXNMK:.........xMWkco0NKd:,;:loddo:...                           //
//                                     ..:KMMMO,.....lXWWk,....,kWMMMx......,:;.:0WWNXOl'..........;:ccc;..                       //
//                          .....      ..;KWWX:.....;KWNx......cXMMMMk,..,lOXWk'.'cc:,.........'ldkO0KNWWKx,                      //
//                      ..':clc;.........,ON0c.......cdc.......'dXWWMW0kOKWWNk;...'..........;dko;'...;OWMMO'                     //
//                     .:kXWMMMNOl'....''.';'...cxxc....;;'......,co0WMWWWWKl....'c,........oXK:......'kWMMO'                     //
//                    .lXMMMMMMMMWO:'cOXKk;....oNMM0,.'xNN0l........,lkOOko,...............lXMO'.....:OWMNk;.                     //
//                    ,0MMMMMMMWWWWNKNMMMMk'...xWMM0,.'kWMMNd;:d000Od:'..........':llc'...cKMMK:.....:xkd:..                      //
//                    ,0MMMMMWNX0kKWMMMMMMk....;0WMXc..'dXMMWXXWMMMMMN0dc'......l0WMMWKc.:KMMMMXxl;'...'.....                     //
//                    .oNMMWWXkc'.:KWWWWMMx.....,kWMKl...:0WMMMWNNNNWMMMW0o,...cXMMMMMMk'cXMMMMWWWNK000KK0Oo'                     //
//                     .kWMWXo... :KXxdONMx.......dNMNk,..;OWMMWk::cOWMMMMWO;..;KMMMMMNl.'xNWWNKOxdkXMMMMMMWO'                    //
//                      :XMMk.    'l:..,0Mk........dWMWO,..lNMMXc...;0MMMMMWd...cXMWN0c....:ooc,....lNMMMMMWx.                    //
//                      .kMMx.       ..,0MO'.......oWMMK;..lNMM0;...'kMMMMMWo...'kWXo'.............,xWMMMW0c.                     //
//                      .xMWd.      ...dWM0,......lKMWWx'.:0MMWd....'OMMMMM0;...;0Wd........',,;;:o0WMMWNx'                       //
//                      .kMXc       ..lNMMk'....cONWWXx,,dXMMMO,.....xMMWWNo...:OWNl.....:x0KXXKXNWMWNKx;.                        //
//                      '0Wx.        ;KMWWo...,xNMWXd;.:0WMMMK:......,d00kl..,dXMMNl....oNWN0dc::cool;..                          //
//                      cXx.       ..'xK0d'...xWWNx,..'OMMWWKc.........''...:0WMMMXc....lOx:.....                                 //
//                      ,;.       .':coxxl,...lOx:.....;dkkd;.........;ko..,OMMMWNx'.....',,.... .                                //
//                               .cOK0KNMWk'..........................':,..'xNNXOl.......dXXx'..                                  //
//                               .','..cKMX:.':lxkxc...........,oxkkxc.......;c:,........kWMWd.....                               //
//                                  ...,OMX:,ONWMMMWx.........'kWMMMMNk;....;oxO00Okd:...:KMMx.........                           //
//                                  ...lXMO''xWMMMMMK:.........dNMMMMMWx'..lXWWWWMMMMNl...dWMKdoxxdol;..                          //
//                              .....,xNWO;...lXMMMMNl.';ldoc'..oXMMMMMO,.:KWKxldXMMMK:...cXMMMWWMMMMNOc.                         //
//                            ..,;;:oKWMNl.....lNMMMMXOOXWMMNo...lOXMMMk'.:Kk,..;0MWO;....oNMNxldXMMMMMNx'                        //
//                           .c0XX0OXMMMW0c....,OMMMMMMMWWWXk;...':kMMWd..;Ol...lNNx'....cKMMk'..xWMMMMMWx.                       //
//                           ,0W0c'.:0MMMMNd'...kMMMMMWNOoc,.....,l0MMNl..;K0;..dWO,...'lXMMNl...oNMMMMMMX:                       //
//                           'OWx...'kWNWMMWk,..xMMMMMNd.........:OXWMNc..cXWkcoKWd...,xNMMM0,...lNMMMMWWNc                       //
//                           .xMWkc:xX0lckXWXc..oWMMMMK;.........'cOMMNo.'xWMWWWMNc..'xWMMMNl....lNMMMMMMK;                       //
//                            ;0WWNX0o'. .,:;..;kWMMMMO,...........:KMWd.cXMMMMMMk'..cXMMMNo.  ..:XMMMMMNo.                       //
//                             .:cc,.        .:ONWMMMM0:;cx00x,....'kMWd.lNMMMMW0,...oWMW0:.     .dNWWWXo.                        //
//                                            ..:0MMMMWNXWMMMWd....,OMX:.'lk00ko'    'odc.        .;ool,                          //
//                                              ,0MMMMMMMMMMMNl...,dNWd.   ....                                                   //
//                                              .kWMMMMMMMWWKl...dXNWk'                                                           //
//                                               'xXWWWNNKkl'.  'd0Oo'                                                            //
//                                                .,ccc:,..       ..                                                              //
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


contract VTMNSTN is ERC721Creator {
    constructor() ERC721Creator("Vitaminisation", "VTMNSTN") {}
}
