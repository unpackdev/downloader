
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Zone 6
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    .'.                                                                                              .'.    //
//    .. ,cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc;..     //
//      .dXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk.      //
//      .dXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'      //
//      .dXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'      //
//      .dXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'      //
//      .dXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'      //
//      .dXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'      //
//      .dXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'      //
//      .dXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk;;cdkKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'      //
//      .dXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXo.   .';coxOKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'      //
//      .dXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKc.'.       .';;lkKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'      //
//      .dXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk.           .....;kXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'      //
//      .dXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0;            .,,'...c0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'      //
//      .dXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXO;                .,,. ,OXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'      //
//      .dXXXXXXXXXXXXXXXXXXXXXXXXXXXXXO,  .,....             .;kXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'      //
//      .dXXXXXXXXXXXXXXXXXXXXXXXXXXXXO,   .'';,.         ..,o0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'      //
//      .dXXXXXXXXXXXXXXXXXXXXXXXXXXXX0,     ..       .,;:::kXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk.      //
//      .dXXXXXXXXXXXXXXXXXXXXXXXXXXXX0;           .':oxxd:.oXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk.      //
//      .dXXXXXXXXXXXXXXXXXXXXXXXXXXXX0;         .:dxxdoc,. :KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKXXk.      //
//      .dXXXXXXXXXXXXXXXXXXXXXXXXXXXXO,         .':lo:.    ,OXXXXXXXXXXXXXXXXXXXKKKKXXXXXXXXXXKOkdd0Xk.      //
//      .dXXXXXXXXXXXXXXXXXXXXXXXXKkoc'            ....     .cloxxdolcccc:ccc:;,,''''cxxkkO000kdodk0KXk.      //
//      .dXXXXXXXXXXXXXXXXXXXXXXKx:.            .          ..                        .:lodololcdOKXXXXk.      //
//      .dXXXXXXXXXXXXXXXXXXXKkl'.             ...         .               .          .,cllclox0XXXXXXk'      //
//      .dXXXXXXXXXXXXXXXXX0d;......                      .                .          .';ldxxOKXXXXXXXk'      //
//      .dXXXXXXXXXXXXXXXKd'..',::,;;.                              .:dolc;..      ..,,..oKKXXXXXXXXXXk'      //
//      .dXXXXXXXXXXXXXXO:  .,;,:c:co,           ..        .'....';cxKXXXXKOlcol;',:lc.  .dXXXXXXXXXXXk'      //
//      .dXXXXXXXXXXXXXOc.  .':;,:ol;.           .....    .dKOOO0XXXXXXXXXXXKOxlccdOKKko;.:0XXXXXXXXXXk.      //
//      .dXXXXXXXXXX0d:.      ...'..                ..'...;0XXXXXXXXXXXXXX0koccok0XXXXXXXOdOXXXXXXXXXXk.      //
//      .dXXXXXXXXkc.                                 ..';kXXXXXXXXXXXX0kdcclx0XXXXXXXXXXXXXXXXXXXXXXXk.      //
//      .dXXXXXXXO,                                      'kXXXXXXXXXKOdl:ldOKXXXXXXXXXXXXXXXXXXXXXXXXXk.      //
//      .dXXXXXKx'                                       :KXXXXXXX0xl:cok0XXXXXXXXXXXXXXXXXXXXXXXXXXXXk.      //
//      .dXXXXOl.                                        cXXXXX0koc:lx0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'      //
//      .dXXOc.                                          ,0XKOdl:ldOKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'      //
//      .oX0:                                            .lkocldkKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'      //
//      .oXd.                                          .';cldk0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'      //
//      .dXo.              ..                       .,cll:'.:OXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'      //
//      .dX0c.           ...                     .'clc,.     c0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'      //
//      .dXX0o;,:c:ldol:c,....  ..           ..';ll:,........c0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'      //
//      .dXXXXXKKXKKXXXXKOkkkkkkOOkoodxxddxkkO00OkkkkOkkO00k0KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'      //
//      .dXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'      //
//      .dXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'      //
//      .dXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'      //
//      .dXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'      //
//      .dXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk.      //
//      .dXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk.      //
//      .dXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk.      //
//       :kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxkl.      //
//    .,. .....................................................................................        .,.    //
//    ..                                                                                                .     //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Z6 is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
