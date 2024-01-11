
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Apakalips
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXNWMNOxdoodKWNXK0KXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWKoc:cclllxKKOxl;:lllc:,:OWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWX00Kx;cOXKo;,lxO0NMWK0XWWWXx;'coxOXWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMNkodxkkdkWMNOkKWWWXKXNWMMMMMN0Okl:ll;,dNMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMNo:0WMMMMMMMWWMMMMMMMMMMMMMMMWWMMWNNMNo.:dOXMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMN0xdcOMWWNNWMMMMWXXWMMMMMMMMMMN00NMMMMMMMNkol:;xWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWKxdOXWN00KXNNX0kdc,:kNWWNNNXNNKd'.;cldOKWMMX0KXkcxXWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMWKOKOONMMW00NNOo:'.. .. .;:o0KXOl:,..... ...:o0X0lc0XOo:lOWMMMMMMMMMMM    //
//    MMMMMMMMMNdcOW0ONMNOK0o,............cKWMMXd:'............;oc.;KMNx..oXMMMMMMMMMM    //
//    MMMMMMMMWd.dWXoxMNOcc;............ .o0OOkO0d. .............'..oNMWo..dWMMMMMMMMM    //
//    MMMMMMMMWo.oXXdlo:cxOO:..''....... ;l'....''..............:0d.'OMWd. :XMMMMMMMMM    //
//    MMMMMMMMM0',odkKk;:0WNd..,'......,oKd.......:c'.........,cOK:.cXWk, .dWMMMMMMMMM    //
//    MMMMMMMMMWk'':clol::lKXd;;'...;lONMNl.......oNXOdc,....:ON0:.:xxl;. ;0MMMMMMMMMM    //
//    MMMMMMMMMMNl.'cldxkx:oNWKklccd0KNWM0, ......dWMWWWN0kxOXMNdcl,;ol;..,OMMMMMMMMMM    //
//    MMMMMMMMMMMNx,,cdOOkddOKKd;cc'..;kN0, .... 'OMNxoKWWWMMMWWNXo.':;'.:0WMMMMMMMMMM    //
//    MMMMMMMMMMMMWk'.;ododkxol:,do....'xK:......cXNxokkloKXxoddollool;.cXMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWKo,.....;;;dkl;.....:0Ko;;:cxXWd','..:l;..''.,cl;';xNMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMNK0Oc....'dOl.....,xMMNXWWMMKc''.....,.. . .oOOKNMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMXd;....';'...'c0MMMMMMMMO;.....',.....:OWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMNKOkkxdool'..oNMMMMMMK:...'cccldddkKWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO,.cNWNNWNN0c'.:0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx,:dkKXXOkdocoXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMkokdooxkkkldxxNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKklOXKOkO0XKddkdOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMNx;'..:XXOOkkOO0dcOk;cddx0NMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMNxl::dxdodXKONMMMMW0dOkcl:;:;oOKWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWKc.;cOWNW0xXOxNMMMMMXxOOdKNNWO;.'cKMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWXK0xl;',xXNMKkKOxXdlNMMMMMWklol0MMKox0x,,okKWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWOl;;l;..,dxoxNMWKklld,;xO000Oxl;cdkKXx;xX0xl,..cxk0NMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMXl'..:c...'..dWMMWXXXXdckXWMMNO:lXMWNXKXWXl;l:..;c'.lXMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMNOdddclollcoOOxkXMMMMMWWMMWN0dx00kO0XNWMWXd;',cldollx0NWMMMMMMMMMMM    //
//    MMMMMMMMMMMNk;.;kd,;:;',kK:..kMXooKOodKWWx..cKo..;kNNKxxxokkxx0Xx'':ld0WMMMMMMMM    //
//    MMMMMMMMWXkl'.:Od..,;..;oc'.,KNo..;.;kNWNo.''lo...;KNo.':,'....,c:'',':xKWMMMMMM    //
//    MMMMMMW0l,,''lkc...',;cc.';.cNO'....dWM0d,.;..::...dNKc.'do..',..,dxc,,;::dKWMMM    //
//    MMMWKxl:;'.,dk:.;oO00d;,:;..xXc.,oc.'kNo..,cc,,l;..,cld:.,kx....,:kNOl:cc..,OMMM    //
//    MMW0ooONKdlOkolxXNMW0loKWXdo0O:;kWO;'l0xldKWW0ool..,cck0l;oKOc,;dKWMWX0kkxxkXMMM    //
//    MMMWMMMMWWMWWNWMMMMMMMMWMMMMMNNNWMWNXNWMMMMMMMWKOddKMMMMWWNWWXOxkXWMMMWNWMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract LIPS is ERC721Creator {
    constructor() ERC721Creator("Apakalips", "LIPS") {}
}
