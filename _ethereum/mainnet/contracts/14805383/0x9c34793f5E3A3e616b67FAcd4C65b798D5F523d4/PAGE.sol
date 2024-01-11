
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tom's Diary
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
//        ..............................................................................     .......              //
//    '...................................................................................................        //
//    '''''............'''................................................................................        //
//    '''''''..'cooodddddddddddddooooolllllllcccc::;;,;coooooooddooooollllccccccccccccccccccccc;. ........        //
//    ''''''''.;xOOOOOOOOOOOOOOOOkkkkkkkxxxxxdddooolcclx0OOOOOOOOkkxxxdddoooolllllllllllllllllo:.  .......        //
//    ,'''''''.;k0OOOOOOOOOOOOOOOOOOkkkkkkkxxxxdddollclk00000OOOOOkkkxxxddddooolllllllllllllooo:.   ......        //
//    ,,,'''',':k00000OOOOOOOOOOOOOOOOOkkkkkxxxdddoolllkK00000OOOOkkkkxxxddddoooolllllllllloooo;.  .......        //
//    ;;,,,,''':k0000000000000OOOOOOOOOOkkkkkxxxdddoolokK0000000OOOkkkkxxxxdddoooollllllloooooo:.  .......        //
//    ,,,,,,''.:O0000000000000000OOOOOOOOOkkkkxxxddoolokK00000000OOOOkkkxxxxdddoooooooolloooooo:. ........        //
//    ;,,,,,,'':O00000000000000000000OOOOOOkkkxxxdddoookKKKK000000OOOkkkkxxxxddddoooooooooooooo;. ........        //
//    ;,'',,,,'cOK00000000000000000000OOOOOOkkkxxxddoookKKKKKK0000OOOOkkkkxxxdddddooooooooooooo:. ........        //
//    ;,''',,,':O0KK00KKKK00000000000000OOOOOkkkxxxddookKKKKKKKK0000OOOkkkkxxxxddddoooooooooooo:. ........        //
//    ;,,'',,,'cOKKKKKKKKKKKK000000000000OOOOOkkxxxddodkKKKKKKKK00000OOOkkkkxxxxddddooooooooooo:..........        //
//    ,,,,,,,,'cOKKKKKKKKKKKKKKKK000000000OOOOkkkxxddodOKKKKKKKKK0000OOOOkkkkxxxxdddddooooooooo:.  .......        //
//    ,,,,',,,'cOKKKKKKKKKKKKKKKKKK0000000OOOOOkkkxxdddOKKXKKKKKKK0000OOOkkkkxxxxdddddddooooooo;.  .......        //
//    ;,,,,,,,'cOKKKKKKKKKKKKKKKKKKK0000000OOOOkkkxxdddOKKXXKKKKKKK000OOOkkkkxxxxddddddddoooooo;.  .......        //
//    :;;,,,,,,cOKKKKKKKKKKKKKKKKKKKK0000000OOOOkkxxdddOKKXXXKKKKKKK000OOOkkkkxxxxdddddddoooooo;.  .......        //
//    ;;;;;;;;,cOKKKKKKKKKKKKKKKKKKKKKKK00000OOOkkxxxddOKKXXXKKKKKKK000OOOOkkkkxxxxxdddddoooooo:..........        //
//    ;::;;;;,'cOKKKKKKKKKKKKKKKKKKKKKKKK0000OOOkkxxxdxOKXXXXXXKKKKKK000OOOOkkkkxxxxddddddooooo:. ........        //
//    ;;;;;;;;,cOKKKKKKKKKKKKKKKKKKKKKKK00000OOOOkkxxdxOKXXXXXXKKKKKK000OOOOkkkkxxxxxdddddddood:.  .......        //
//    :::::;;;,cOKKKKKKKKKKKKKKKKKKKKKKK000000OOOkkxxdxOKXXXXXXKKKKKK0000OOOOkkkxxxxxdddddddddd:.  .......        //
//    ;;;:;;;;,cOKKKKKKKKKKKKKKKKKKKKKKKK00000OOOkkxxdxOKXXXXXXXKKKKK0000OOOOkkkkxxxxxddddddddd:. ........        //
//    ;;;;;;;;,cOKXXXKKKKKKKKKKKKKKKKKKKKK0000OOOkkxxdxOKXXXXXXXXKKKK0000OOOOkkkkkxxxxddddddddd:. ........        //
//    ',,,,,,,,cOKXXXXXXXXXXXKKKKKKKKKKKKK0000OOOkkxxdxOKXXXXXXXXKKKKK000OOOOkkkkkxxxxxdddddddd:. ........        //
//    '''',,,,,lOKXXXXXXXXXXXXKKKKKKKKKKKK0000OOOkkxxxxOKXXXXXXXXXKKKK0000OOOkkkkkxxxxxdddddddd:. ........        //
//    ''''''','cOKXXKKXXXXXXXXKKKKKKKKKKKK0000OOOkkxxxxOKXXXXXXXXXKKKK0000OOOkkkkkxxxxdddddddddc. ........        //
//    ,,,,,,,,,cOKKXKKXXXXXXXXKKKKKKKKKKKK0000OOOkkxxxxOKXXXXXXXXXKKKK0000OOOkkkkkxxxxxdddddddxc. ........        //
//    ;;;;;;;;,cOKKXKXXXXXXXXXKKKKKKKKKKKK0000OOOkkkxxxOKXXXXXXXXXKKKKK000OOOkkkkxxxxxxxxxxxxxxc. ........        //
//    ;;;;;;;;,:x0XXXXXXXXXXXXKKKKKKKKKKKK0000OOOOkxxxxOKXXXXXXXXXKKKK000OOOkkkkkxxxxxxxxxxxxxxl.  .......        //
//    ,,,,,,,;,'':odddxxxxxxxxxxxxxxxxxxdddddooolcc::;,:clooooddddddddddddooolllccc::::::;;;,,,'.  .......        //
//    ,,,,,,,,,;'..'.''''.........................       .......................                 .........        //
//    '....'''''''''''....................................................................................        //
//    ''..'''''''''',''''''''...................................................  ...................             //
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PAGE is ERC721Creator {
    constructor() ERC721Creator("Tom's Diary", "PAGE") {}
}
