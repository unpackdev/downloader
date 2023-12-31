// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nightmare on Blockchain Street
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                           //
//                                                                                                                                           //
//                                                                                                                                           //
//        )                                                                                                   (                              //
//     ( /(             )    )                                     (  (             )       )                 )\ )   )                )      //
//     )\())(  (  (  ( /( ( /(   )      ) (     (                ( )\ )\         ( /(    ( /(    ) (         (()/(( /((     (   (  ( /(      //
//    ((_)\ )\ )\))( )\()))\()) (    ( /( )(   ))\    (   (      )((_|(_)(    (  )\())(  )\())( /( )\  (      /(_))\())(   ))\ ))\ )\())     //
//     _((_|(_|(_))\((_)\(_))/  )\  ')(_)|()\ /((_)   )\  )\ )  ((_)_ _  )\   )\((_)\ )\((_)\ )(_)|(_) )\ )  (_))(_))(()\ /((_)((_|_))/      //
//    | \| |(_)(()(_) |(_) |_ _((_))((_)_ ((_|_))    ((_)_(_/(   | _ ) |((_) ((_) |(_|(_) |(_|(_)_ (_)_(_/(  / __| |_ ((_|_))(_)) | |_       //
//    | .` || / _` || ' \|  _| '  \() _` | '_/ -_)  / _ \ ' \))  | _ \ / _ \/ _|| / / _|| ' \/ _` || | ' \)) \__ \  _| '_/ -_) -_)|  _|      //
//    |_|\_||_\__, ||_||_|\__|_|_|_|\__,_|_| \___|  \___/_||_|   |___/_\___/\__||_\_\__||_||_\__,_||_|_||_|  |___/\__|_| \___\___| \__|      //
//            |___/                                                                                                                          //
//                                                                                                                                           //
//                                                                                                                                           //
//                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NoBS is ERC1155Creator {
    constructor() ERC1155Creator("Nightmare on Blockchain Street", "NoBS") {}
}
