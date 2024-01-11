
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CosplayMembershipPassNFT
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                                                                      //
//    ==:;=:i,:::i;::::+=;=::=+++++=:==,,:=++++iiiiiii++=;;:,        ,:,,               //
//    ;;:===+,:,:=:::;;=;:;,;+i++i+ii===;,:;=+++iiiiii++i+==;:,       ,,,               //
//    :::;=:;:,:,;:,:=;=+,,;:i++ititttt+=;:::;==+ii+++iii++++=;:,,     ,                //
//    ,,,,:,,,,,,::,:=i;;,:i:iitttIIIIIIttti++=;===+++iiii+iii+=;:,              ,,     //
//    :,:,,:,,,:::::::;=+;:i==ittIIYYYYIItiiiiii+==+iiiiittiiii++=::   ,   ,     :,,    //
//    :,,,,,  ,:::;;;;=tt;:ii;ittIIti+=;;====;;===+iiiitttttttttt++;:;=;;,::,, , :,,    //
//    :       ,,::;=++=+i+=+i+=++=;;;;;;=++iiiitiiiiiiitttIIIIIItti+=+=+;;;,  ,,,,,,    //
//    :       ,:,:;=+itti+==;=;::,,::::;+iittiii+++=++ittIIIYYYIIti+===+=::   ,;,:;,    //
//    ,   ,,,, ,::;+iiitttii;;::,,::::::::::::,,,::;;=+tIYYYVVYIItti+===:;    ,::::,    //
//              ,:;=+itIIIIt+=;;;;;::,,,;,;=     ,,:=iIYVXVXVVVYIttii=+:::,   ,,,:,,    //
//     ,       ,,,,:==tIIYIIIi++==;:::iIV;:, ,;;::+IYVXRRRRRXXVYYIttt++;;:    , ,,,,    //
//           ,   ,,:;+tIYYVVYIIti+=+=iIYVVti++===iYXRBBBBBRRXXVYYItiIi===:,     ,,,,    //
//          ,    ,,,:;+tYVXXXVYItItYIYIYIttitiitYVRBBBBBBBRRXXVYYIttti+==:,,,   ,:,,    //
//         :::,,  : ::,:iVXRRXVYYVVVXVYIIttttIVXRBBMMMBBRRRXVVYYIIttii+=;:,,,,,,,,,,    //
//          ,,  ,+t:,,,:;YRBBRXXXXXRRRRRRRRRBBMMMMMMMBBBRRXXVVYIItt+++;;;;,,,,,,,,::    //
//           , ,,+tt++tIIYRMBBRRRRRBMMMMMMWWWWWWWWMMBBBRRRXVVYIIti+;;;;:;;:,,,,,,:,:    //
//          ,,,=;;=itttIYVBMMBBRRRBMBMMWWWWWWWWWWWWMMBBBRXXVVYIIti=;:::::=;:::,::,,:    //
//          ,:,=ttttItIVXXBMWMBBRBBBMMMMWWMWWWWWWWWMMBRRXXXYYIIIti+;::::;=;;::;=:,,:    //
//       ,,,,;::IYVVXXRRRRBMWMMBRRRRBBRBBBMMMMMWMMMMBBRRXXVYIIIItit=;::;=+;=;;R:;::;    //
//    ,    ,,::,IVXRRRBBBRMMWMMBBRRXRBRXXXRRRRBBBBBBRRXXVVYIIIItttIi==;==+===VI:;:,:    //
//    ,    ,,,:,tVXRBBBBBBBMWWMMBBRRRRVYIYVXXXXXXRXRXXVVYYIItItItttii+==++==;M;;;,,:    //
//    ,,  ,,,,,:=VXRRBBBBMMMMMMBVYVYIIiii+IVVXVVVVVVVVVVYYYIItittti+i===+=;==R:;:::,    //
//    ,,,,, ,,,:,IVRRRRBXRRRRXVI+;::::;==iYXRBBRRVVYVYYVYYYIi+++iii+====+;;;=t:;,,:,    //
//    ,,,,, ,,,::=VXXXXXXIIYIti=;,:;=itIYVRRBBBBBBRXXVYVVVYYIi=++ii++===;;;::=:,,:,,    //
//    :        ,::iXXXXVVYIYYi+=;;+tYVXRBBMMWWWWBBBRRBBRRRRXYYi+iiti+==;;::,,;  ,,,     //
//    :         ::,+YYYIItiYXVYIIIYXRMWWWWWMMBRXYItiiYXRBMRXVYtttIti+=;;::,,,:, ,,,,    //
//             ,:: ,;tIttiiVVXXXXBMMBRXVYYIi+==+++iIRBMBRMRXVIttitti+=:::,,, ,, ,:,:    //
//             ,:   ,+iIYIIVYVYIIIttiiii++ttIYIIIVRBMWWWBBRXYIittii+=;::,,     ,,, ,    //
//    ,        ,  , =i,=YXRRXVYI++i++itYXXXVttIVXXBMWWWMBBRXYtti+++==:::,       ,       //
//    ,,:,,,        i  ,;IXRRRBRYYYYYYYYYIIIYYVXRBMMMMMMBBXVYi++===;:,::       ,,       //
//    ;;:,,       ,,:  ,,:+IVXRBVIIIIIYIIIIIYVXRBMMMBBBBBRVYt+====;::,,,      ,,,,:=    //
//    +=;:,,, ,   ,,:   ,;,:;tVXRYIIttttIIYYVXRMMMMMBBBRVYIi+=;;;;:,,       ,,,,,;=+    //
//    t+;:::,,::,,,,+ ,::, , ,:iXXVYYIIIIYVXRBMMMMMBRXXVYIi+;;;;::,       ,,,,::::;:    //
//    i+;;:;;:==:,:,;,,        ,;VRXXRRRBMMMWWWWWMMBRVVYIt=;::,,,        ,::;,,,        //
//    ii===;;:=+;;::,,,         ,;XBBMMWWWWWWWWWMBRRVYIti=;,,,,      ,,:;=;;,, ,,       //
//    ii+==;;:=+:;::,,          ,,;XBBMWMMMMMMMBRXXVIti+;:,,          :;:;:, ,  ,       //
//    ti=;=;,,:;,;:,,,,           ,;YRRRRRRRRVVVYYti+=;:,            :::,,   ,,,        //
//    ii+;;::,,,:::::: ,            ,=tIYYYItti++=;::,,,            :  ,,,  :, ,        //
//    Ii+t=;::,,:,,,,:;:,           ,,,,::;;;::,,,:=+i+:,          ,, ,::,, ,:,,  ,     //
//    tiiit+:,,,,,,,,,::,,           ,      ,    ;tIYYYi=,         ,,:::,,,,,;:,,,,     //
//    i==+i+;:,,, ,:,,,,                       ,;IYVXVVVI+:,,     ,,:::,,,,,,::,,,,,    //
//    ==it+;=:,, ,::,,,  ,,,                 , ;+YYXVYYIti=:,,,,,  ,:;;::,:::,,,  ,     //
//    =+IYii=::,,,:,,,,,,:,,,            ,, ,,,:+itt+=;;:::;, ,,,,,,,,:::,,,,,,:,,      //
//    IVVVYt=;::,,,,,, ,::,,,         ,       ,::;::,,,, ,,:::,:,:, , ,,,,,,,,::;:,,    //
//    XRRXYi+++:,:,,,,,,;;:,,  ,             ,::,,       ,,::;:::,, ,  , ,, :,::;:::    //
//    VYtiitt+;;,:,,,,,:;;,,,     ,      ,, ,,,,        , ,,,,::,,,,,,,, ,,,,,;;;:;=    //
//    ===itti=;:;::,,,,::,,,,           ,,,         ,  ,,,,::;;:::::::,:,,,,,,;;===;    //
//    +iIYYII+:::=;;:;:;,,,:,,           ,,          , ,,,:;;;::,:+=;;,:,,,,,:;;;;=:    //
//                                                                                      //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////


contract COS is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
