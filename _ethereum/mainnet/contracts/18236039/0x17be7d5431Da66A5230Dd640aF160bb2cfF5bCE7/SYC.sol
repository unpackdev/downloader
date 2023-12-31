// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sycamore Gap Memorial
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdodooddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdoll    //
//    lodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdolc:;;;:::::codxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddoc:::    //
//    :clodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdocclcc;,;;;;;;,;:coxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdllcllc:c    //
//    ;;:ccldxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdoccc::;,;:;;;;;;;;ldxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdolc:::::::;    //
//    ,,,,;:clodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdlc::ccc;;,,,,,,,;:,,;oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdolc::c::;;;;;;    //
//    ,,,,;;;;;cldxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdolc::ll;;:;,,,;;:c:;,:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxolcc:::::cc;;;;:c    //
//    ,,,,,,,,,,;:cloxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxl::c:;;;;;,,,;;,,;;,,;:cldxxxxxxxxxxxxxxxxxxxxxxxxxdolc::c;;:cccc:cc:;::    //
//    ,''''''''',,;;;cloxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdc,;:,,;;,,,',;;,,;cc;,,,:lxxxxxxxxxxxxxxxxxxxxxxdol::;;;::;,;;:c::::,',;    //
//    ,,''''''''',,,,,,;:codxxxxxxxxxxxxxxxxxxxxxxxxoc,,;;,,;::,,;:c:,,,:lolc:ldxxxxxxxxxxxxxxxxxxxdlcc:;;;;;,,;;;;;;;;;,,',,;    //
//    ,;,,,,,,,,,''''''''',:clodxxxxxxxxxxxxxxxxxxxdc::colc::cc;':ll:;::;;:ccodxxxxxxxxxxxxxxxxxdolc:::;,,,,,',,,,,,,,,,,;,,',    //
//    ,''',,,,'''',,,,,,,,,,,,,;clodxxxxxxxxxxxxxxxxxdllooloodo;.;ccclllc:;;;:lxxxxxxxxxxxxxdoolcc::,,,,,,';;,,,,,,'',,,''',,,    //
//    ,,,,;,,,',,,,,''''',,,,''',,,;:clodxxxxxxxxxxxxdooddddxxd:':odxxxdddoooodxxxxxxxxddolc:::c::;;;,;;,,,;;,,,,,,,,;;;,,,,,,    //
//    ;;;;;,,;,,;;;,,,,'''''''''''''''',;:lodxxxxxxxxxxxxxxxxxxc:dkxxxxxxxxxxxxxxxxdoc:;;,;;:::::;;::;;;;;:;;;;;;;;;,,;;,,;;,,    //
//    :::::;;;::::::;;;,,,,,,,'',,'''''''''',:cccllodxxxxxxxxxd;;dxxxxxxdolcc:::clc:,',,,;;;;;;;;;;::;;::;;;::::;;;;;;;:;,;:::    //
//    ,';:::;;::::;::;:;,;;;;,,,,,,,;;,,,'''',,''',,;::cccc:::;'';::::c:,'''''''',,,,,,,',::;;:::c:::::::::::cc;;::::::::;:ccc    //
//    ,;:ccc:::::::::;;;;:;;,,,,,;:::;,''''''''''''',,,,,,,,,,,,,,,,,''','',,,,,,,,,;,;,,,;::clc:c::ccccc::::cc;:ccllllc:;;ccc    //
//    ;:::;;;;;,;;,,,,,,;,,,;;,,;;;:;,,;;;::::::::::;;;::::;;;,,,,;;;;::;,,,,'',,;;;:;::;;;:cllccccc::clc:;:ccc;:lolcclc:;:c:c    //
//    ;::c:;;;;,,;;;;::::;;;:::::::c:;:::::c:::ccllcc:::::c::::::ccccccccc:::::ccc:ccc:;;::c::;;cc::c::lolc:;;;:ccc::::;::::;:    //
//    :::;,'''',:::;,;:cccccc::::;;;;,;;;:;;:::;::::::;;:::cclc:cccccc;;;;;::::;:::;;;;;;;,;,,,;::;;;;;:::;,,;;::;;;;;;,;:cc:;    //
//    cccc:::ccccc:;;::ccc::;::;;,',,;,;;:;;;:::;;:::::::ccllllllllccc;,,;::::;;::;,,;;,,,;;;,,,;::,,;;;;;;;::;;;;;;;:::;:::::    //
//    ooooooooolccc:;;;;cc:;,,,,,,,,;;;;;,,;;::::cccccccllcc:::c:::;;;,,,;;;:cc:::;:cll::cc:;,'',;;;;::;;;::::;;;::;;;,,,,,;:;    //
//    cccclooooolll:;::::;;;;,'',,,,,,,,,'',;::;,',;,,::;;;:;;;;,,;;,,'',,;;:;;;:::cc::;;:cc::::::::::;;,,;::;;;,',,''',;:cc:;    //
//    c::::cc:clllllcccc:::clc,',;;,'''''''',,,,'.'',;;;;,,,;:::;:c::;;:c::::;,;clllc::::::;;;,,;;;,''..'',;;;:;;;;;,;::c:c:;,    //
//    cccc:;'.,;;;;;::cc:;;:cc;,;:::;,''..'''',;,;;,;::;;,'';;:lc::;,;;:cccc:cc:cllcccloolc;,''',,;,',,',,;;:::::::;;;;;;;;,''    //
//    ,;;;,'.'',,,,,,:cclc:;,'',;;;:c::;'',,,,;;,;;,;;;;,'',;:::;,;;,,,,,;;:;:::;;;,,,;;:;;,,,'',,,'.',,;;;;;;;;;;;;,,,',;;;:c    //
//    ,,,,,,,;;;;::::ccc::::;;,;:cccc:::;;;;,,''',;;;::;,;;;;;;:;;::c:;,,;;:,;:;;,,'',,;:::::;,,,,;,,,;;,,,;,;;:;,,,,,'.,,;clo    //
//    ,,,,,,;;,;::cclllc:;;:::;;;;;;;;;;;,''''',,;;;;;:;;;,''',;,:ccc:;;:::;;;:cc:;,,;:lllc::;,,,,;,'',,','',;:;'.',,;;;::ccc:    //
//    ';::cccccccc:::cloloolclolc:;,,,,;:,''''',;::;,,;;;;,,,;,',,,,;;;;,,;;;;;;:;'',',;:;;,,,,,''''''..',,,;cc;,'',;;;;::::;;    //
//    ,::::ccc:;''',:coolll::clc:;,,;:,;c:,,';::ccccc:;;::::;,..','',:c:;;::,''.''...,,;;:::;,;:;'','''.',,;:c:;;:;;;;;,;;:;;,    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SYC is ERC1155Creator {
    constructor() ERC1155Creator("Sycamore Gap Memorial", "SYC") {}
}
