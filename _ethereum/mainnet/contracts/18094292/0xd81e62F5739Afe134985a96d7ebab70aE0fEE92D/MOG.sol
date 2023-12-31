// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Memes Of Gaws
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWOlxXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOdkNMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMW0kk:,lxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOo;::dNMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMXk0NO;..,ckNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXko:',dOkKMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWOkXNXo'.'.'cOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOl;..'c0Kk0WMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMXk0NXNO;.'.'.'l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMXko:'.'.,dKXOOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMM0kXNNNXo.......,o0WMMMMMMMMMMMMMMMMMMMMMMNOo;...'..,kXN0kXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMNkONXNXNO;.'......,lkXMMMMMMMMMMMMMMMMNKOd:'.......;kXNKkKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMKkKNNNNNXo........'.';lx0NWNXXXNMNKkxl;'..........;ONNXkOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMM0kXNNNNXNO;.'...........,::;;,;:l:'.........'.....oXNNOkNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMM0kXNNNNNNXo...'................................'..lKN0kXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMM0kXNNNNNXNO;.'.'''......'',,,'''....'.'.........'.,cdloKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMKkKNNNNNNNXl.......'',;;;;;;;;;;,,......'''',,,;;;;;;;;:ld0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMNkONXNNNNX0l'',,,;;;;;;;;;;;;;;;;;;,'.',;;;;;;;;;;;;;;;;;;;l0WMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMOkXNNKkdl:,;;;;;;;;;;;;;;;;;;;;;;;;;;,',;;;;;;;,,,,,,,,,,,,;ox0NMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMKk0Ooc;;;;;;;;;;;;;;;;;;,,,,,,,,,,,,;;;,,,,,,,,,,,;;;;;;;;;;;;;cd0WMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMXd;;;;;;;;;;;;;;;;;,,,,,,,,''''',,,,,,,,,,',;;;;;;;;;;;;;;;;;;;;;;;dNMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMXx;..,;;;;;;;;;;;;;;;;;;;,'...''.......''''''',;;;;;;;;;;;;;,,,,,,,,',kMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMNx;..';;;;;;;;;;;;;;;;;;',cldkOOx;.  .'.  ..'c;..,;,,'''.'..........;:::l0MMMMMMMMMMMMMMMMMMM    //
//    MMMMMNk:...',;;;;;;;;;;;;;;;;;;,;dKWMWO,   .cc.    cNXOo;,;;clod:.    ',. .lXWXkKMMMMMMMMMMMMMMMMMMM    //
//    MMMMMXdlc,...,;;;;;;;;;;;;;;;;;;;;:lxx'.l:. ',.  .'xWMNOkKXNWMM0' .,. ..   '0NxxNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMWXl..';;;;;;;;;;;;;;;;;;;;;;;;,'':'  .'. .l0KKklcdKNMMMMk. ..  ,,   ,do,lNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMKl'..,;;;;;;;;,;;;;;;;;;;;;;;;;;;;,'.....,lol;,,,,:loddxd'    ....'',,:d0WMMMMMMMMMMMMMMMMMMM    //
//    MMMMMNk;....';;;;;;;,,,;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,,;;;;;;;;;,,'',,;;;;,,,xWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMXdo:....;;;;;;;;,,;;;;;;;;;;;;;,,,,,,,,,,;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,,:oxxkOXWMMMMMMMMMMMMMMM    //
//    MMMMMMM0;.'.';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;'..:oKWMMMMMMMMMMMM    //
//    MMMMMWO:....',,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,. ..,OWMMMMMMMMMMM    //
//    MMMMWk,.......';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,....;OMMMMMMMMMMM    //
//    MMMWk:;..'....';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,...oWMMMMMMMMMM    //
//    MMMWKx;.''....','',;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:,lXMMMMMMMMMM    //
//    MMMMXxdOo'.'......';;;;;;;;;;;;;;;;;;oo,cxc;oo;:oddo:;lo:;cc:,,;;;;;;;;;;;;;;;;;;;;;;;:,cKMMMMMMMMMM    //
//    MMMMMMMNl.......'..;;;;;;;;;;;;;;;;;;::,:l:,lo;:dKNO:;xOc;oOd,,ldc'';oo;,loc,:c;',;;:;,'lNMMMMMMMMMM    //
//    MMMMMMWOcoo,.'..'..,,',;;;;;;;;;;;;;;;;;;,;;,',,,;:;,,,,,,,;;;;;:;;;;cl;;cxo,:l;,,;,:;,lKMMMMMMMMMMM    //
//    MMMMMMWXXW0:...........,;;'',;;;;'',;;;,,,;;;,,',,,,,,''',,,,',,,,,,;::::;;,,;,,;;;;coONMMMMMMMMMMMM    //
//    MMMMMMMMXd:,....''......'....';,....','...'',;'',,,;;;,',,,;,:l:,,cxKXXKKK000OOkkkO0NWMMMMMMMMMMMMMM    //
//    MMMMMMWOc;;;,..,;;'..,'...''...............''',;;,,,,,,,;;,,'oNKkONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMXd;;;;;;,,;;;;',;;,',;;'..,;,..';,'',;;;;;;;;;;;;;;;;;;;;dXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMW0c;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,;;;;;;;;;;;;;;;;;;;;;;;;;;;oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMNk:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MNd;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,'''',;;;;;;;;;;;;;;;;;;;;;;xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MO;;;;;;;;;;;;;;,,;;;;;;;;;;;;;;;;;,.......';;;;;;;;;;,,;;;;;;;;,cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MOG is ERC721Creator {
    constructor() ERC721Creator("Memes Of Gaws", "MOG") {}
}
