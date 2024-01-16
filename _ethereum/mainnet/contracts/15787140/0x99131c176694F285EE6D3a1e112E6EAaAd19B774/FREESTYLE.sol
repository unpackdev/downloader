
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Freestyle Friday
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    :::::ccccccccclllllllloooooooooooddddddddddddxxxxxxxxxxxxxxxxxkkxxxxxxxxxxxxxxxxxdddddddddddoooooooooolllllllllccccccccc    //
//    :::::ccccccccclllllllloooooooooooddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddddddddddddooooooooolllllllllccccccccc    //
//    :::::ccccccccclllllllloooooooooodddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddddddddddddooooooooolllllllllcccccccc:    //
//    :::::cccccccccllllllllooooooooodddddddddddddxxxxxxxxxxxxddooooodddxxxxxxxxxxxxxxxxddddddddddoooooooooolllllllllcccccccc:    //
//    :::::cccccccccllllllllooooooooddddddddddddddxxxxxxxxxdoc;,,,,,,;;;:codxxxxxxxxxxxxxdddddddddoooooooooolllllllllccccccc::    //
//    ::::::cccccccclllllllloooooooddddddddddddddxxxxxxxddl;..........''...;codxxxxxxxxxddddddddddoooooooooollllllllcccccccc::    //
//    :::::::cccccccclllllllooooooodddddddddddxxxxxxxxdoc,'......     .......;:lodxxxxxxddddddddddooooooooooollllllccccccccc::    //
//    :::::::ccccccccllllllllooooooodddddxxxxxxxxxxxxdl;............ .  .....'',,:ldxxxxxdddddddddoooooooooollllllcccccccccc::    //
//    ::::::::cccccccclllllllooooooodddddxxxxxxxxxxdo:....    ......... ..   ..'..':odxxxxddddddddoooooooooolllllcccccccccc:::    //
//    ::::::::cccccccclllllllooooooddddddddxxxxxkxxo,....  ..',;;:::;;;;,,'....... .,lddxdddddddddddooooooolllllccccccccccc:::    //
//    ::::::::ccccccccllllllloooooodddddddddxxxxxxd;. ...',:clloooooooollllcc:;,'.. .,coddddddddddddooooolllllllccccccccccc:::    //
//    :::::::::ccccccclllllloooooooodddddddddxxxxdc. .',;:clooddddddddddoooolllcc:,.  ':oddddddddddoooooollllllccccccccccc::::    //
//    :::::::::cccccccllllloooooooooddddddddddxxxdc..';::cloddxxkkkkkkkxxxddoolllc:,.  .:odddddddooooooolllllllccccccccccc::::    //
//    :::::::::cccccclllllllooooooooddddddddddxxdo:..;:cclodxxkkOOOOOOkkkkkxxdoolcc;,.  ':oddddooooooolllllllllccccccccccc::::    //
//    ::::::::::cccclllllllloooooooddddddddddddddo;.';clloodxkkkkkkkkkkkxxxxxxddolc:;'. .,cooooooooooollllllllllccccccccc:::::    //
//    ::::::::::ccccllllllooooooooodddddddddddxddl'.,;cllodxxkkkkkkkkOOOkkkxxxxdoll:;,.  .;looooooooolllllllllllccccccccc:::::    //
//    :::::::::cccccclllllooooooooodddddddddxxxxdc..,:lodxxkOOOOkkOO00000OOOkxxolllc;,.  .,cooooooollllllllllllccccccccc::::::    //
//    :::::::::ccccccclllloooooodddddddddddxxxxxdc'.,:llllloxO0000KK00kxxxxxxxxolllc:;.. .':looooollllllllllllcccccccccc::::::    //
//    ::::::::::cccccccllllooooodddddddddxxxxxxxdc'.'.',;;,,:okOO000koc;;;::::cc:ccc:,.. ..;loooollllllllllllccccccccccc::::::    //
//    :::::::::::ccccccclllloooodddddddxxxxxxxxxo:'.',::::::::cdO00Odlcc:::clol:;:ccc;.. ..,cllollllllllllllcccccccccccc::::::    //
//    :::::::::::ccccccclllloooodddddxxxxxxxxxxdl,.,:;.',,:ddl:lkOOxcclcc;,;:;:llolcl:...',,,:cllllllllllllccccccccccccc::::::    //
//    ::::::::::::cccccccllllloooddddxxxxxxxxxxdl;';cc;:ccodoc:lkkkxlloooololcclodolc:'.;ccl;':lllllllllllcccccccccccc::::::::    //
//    ::::::::::::ccccccccllllooooddddxxxxxxxxxxl;,;clloooddl::oxxdddddxkkkxdddddooc:;',ldoo,.:llllllllllcccccccccccc:::::::::    //
//    ::::::::::::::ccccccllllloooodddxxxxxxxxkxdc,;:ldxxxddl::oxdooddxkOkkkkkxdoolc;,,:dxd;.,clllllllllcccccccccccc::::::::::    //
//    ::::::::::::::cccccccllllooooddddxxxxxxxkxdc,,cdkOOOOxc:dkxdollook000000Oxdllc;'';lol'.:lllllllllcccccccccccc:::::::::::    //
//    ::::::::::::::ccccccclllllooooddddxxxxxxkxdc';ldkOOOkl;:oxxolcllldOkO0KK0kdolc;'.,ll,.,cllllllllccccccccccccc:::::::::::    //
//    ;;:::::::::::::ccccccclllllooooddddxxxxxxxdc',codddooc,';:c:::::coxxdxkOkxdolc;..':,.,clolllllllcccccccccccc::::::::::::    //
//    ;;;;::::::::::::ccccccclllllooooddddxxxxxxdc'':llc;;;,,,,;:;;;,',;:ccclodddol:'.....;cllllllllllcccccccccc::::::::::::::    //
//    ;;;;;::::::::::::ccccclllllloooooddddxxxxxdl,.,cl:;,,',:::::::::::;;,,;ldxdl:,....':llollllllllllccccccccc::::::::::::::    //
//    ;;;;;::::::::::::cccccllllllloooooddddxxxxxd:..,::;:c,'cdkO00K0Okdc:c:,cdoc;'.. .':loollllllllllllccccccc:::::::::::::::    //
//    ;;;;;::::::::::ccccccclllllllloooooddddxxxxxo;..''':cc::coxkOOxdlclodc';:;,'....':loooollllllllllllcccccc:::::::::::::::    //
//    ;;;;;::::::::::cccccccclllllloooooodddddxxxxdo;....':clllodddxxdooolc;...'.....'codddooollllllllllllcccccc::::::::::::;;    //
//    ;;;;;;::::::::ccccccccclllllloooooooddddddxxxdo:.. .':clcccclcclllc;,..  .....'codddddooollllllllllcccccccc:::::::::::;;    //
//    ;;;;;;:::::::::cccccccllllllloooooooodddddddool:,....',;:;:ccccc:;,'..   .',,.'cddddddooooollllllllccccccccc::::::::;;;;    //
//    ;;;;;;;::::::::cccccccllllllllooooooooodoollol:'';;'...;:cclllc;,,'.. ..';;;;,::clooddoooooolllllccccccccccc::::::::;;;;    //
//    ;;;;;;;;::::::::ccccccllllllllloooolllllloxko;'.':::;'''',;;;;;'.....',::::::,:ddddollloooooolllllccccccccccc:::::::;;;;    //
//    ;;;;;;;;;:::::::cccccccllllllllcclodkkkk0KKXk:,,,:lllc:;,'''''''.',;:cccccc::,;d0KXKOkdlcclllllllllccccccccc::::::::;;;;    //
//    ;;;;;;;;;;:::::::cccccclllccccoxkOKKKKKKXXXXXx::;:loooollcccccccccclllllllcc:::xKKXXXXXKkdolcccllllccccccc::::::::::;;;;    //
//    ;;;;;;;;;;;:::::::::c:::ccloxOKXXXXXXXXXNNXXXXOl:cloddddoooooodddooooooolllcccoOKKXXXKXXXXKOxdoc:::cccccc::::::::::::;;;    //
//    ;;;;;;;;;;;;;::::::;:lodxO0KKKKXXXXXNNNXNNNXXXXKxoooddxxddddddddddooooooooolld0XXXXXXXXXXXXXK00Oxdolc::::::::::::::::;;;    //
//    ;;;;;;;;;;;;;;:;;;coxO00000KKKXXXXXXXXXXXXXXXXNNXKOxddxxxddddddddddddddddddxOKNNXXXXXXXXXXXXXXXKK00Okxoc:;;:::::::::;;;;    //
//    ;;;;;;;;;;;;;;;:ldk0000KKKKKKKKKKXXXXXNNNNXNNNNNNNNXK0OkkkxxddddxxxxxddxkOKNNNNNNXXXXXXXXXXXXXXXXXKK00Okxl;,;::::::;;;;;    //
//    ;;;;;;;;;;;;,:dkOO0KKKKXXXXXXXXKKKKKKKXXXNNNNNNNNNNNNNNNXXKK00000000KKKXNNWWWNNNNNNNNNNNNNNNXXXXXXXXXKK0Okoc;,;;:::;;;;;    //
//    ;;;;;;;;;;;,:xOO0K0KKKXXXXXNNNNNNNXXXXXXXXXXXNNNNNNNNNNNNNWWWWWWNNWWWWWWNNNNNNNNNNNNNNNNNNNNNNXXXXXXXXXKK0Oxo:,,;;;;;;;;    //
//    ;;;;;;;;;;,;dOOKXK0KKKKXXXXNNNNNNNNNNNNNNNNNNXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXXXXXKKOkd:',;;;;;;;    //
//    ;;;;;;;;;,;oO0KXXK0KKKKKKKXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXXKKKOkd;.,;;;;;;    //
//    ;;;;;;;;,,lxOKXXXK00KKKKKKKKKKKXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNWWNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXKKK0Oko'.,;;;;;    //
//    ;;;;;;;;,:xkOKXXXK00KKXXXXXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKKXX0OOk:.';;;;;    //
//    ;;;;;;;,,okOO0XXXKO0KXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXXNNNXKKXX0OOOd,.,;;;;    //
//    ;;;;;;,,:dkkkOKXX0OKKXNNNNNXXXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXXXNNNXKKXX0OOOkc.';;;;    //
//    ;;;;;;,;lxkxkO0KK000KXNNNNNNXXXXKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNXXXXXXXNNNXKXXXKkkOOo'.,;;;    //
//    ;;;;;,,:dkxxOOk0K00K0KXXXXNNNNNX0O0000KKKKKK0000KKKKKK00000000KKKKKK00000000000KKKKK00KKKKK00000KKKXXXXXKKXK0kkO0k;.,;;;    //
//    ;;;;,,;cxkxxO0xk000K00KXXXXNNXXKOOO0KKKKKXXXXKKKKKXXXKKKKK0000KXXXXXXKKKKK0O000000OOOOOOOOkkkxxx0KKXXXXXKKX0OkkO00o'.;;;    //
//    ;;;,,;:lxkxdk0kdkO000O0KXXXXXXK0OO00KKKKKKXXXXKKXXXKKKK00KKKKKKXXXNXXXNNXXKKKKKKKK000000000OOkxxOKKXXXXX0K0OOkkO00k;.,;;    //
//    ;;;,:lcoxkkxxOOkdkO00OOKKXXXKK0OOO0KKKKKKKXXXKKKKKKKKKKKKXXNNNNNNXXXXKXXXXKKXXXKKKKKKKKKK0000OxxO0KXXXXK0OOOOxkOO00o'.,;    //
//    ;;,,locdkxxxxkOOxxkkOkxOKKKK00OOOO00KKKKXKKKKKKKKKXKK0KNNNX0Okk0XNNXKKKKXXKKXXXXXXXXXXXXXKK00Oxdk0KKKXXKOkO0kxkOO00k;.,;    //
//    ;;,;doldkkxxxkkOkxxkkxdO000000OOO00KKXXXKKKKK000000000XXOO0OOkxdook0K00KKKKXXXNNNNNNXXXXXXK00OxdkKKKKKKKkk0OxxkOO0OOl.';    //
//    ;,,cxdldkxxxxxkkOxdxkxdkOOkkkxddxkO0KKXXXXXKKK0000K00KXOk0XXXK00kc;lO0OOKXXNNNNNNNNXXXXXKKK00Odd0KKKKK0Oxk0kxkkkOOOOd'.,    //
//    ;,;lddoxkkxxxxxkkkxxxxolddoddxkxodxkOO00KKXXXXKKKKK00K0xdxkdcodo:,,cxkOO0XXNNNNNNNNXXXXXKKKK0koxKKKKKOkxdkkxxxkkOOOOx;.'    //
//    ;,cooddxxkkkxdddxkkxxxoc:clxkOOOxxkkO00O0KXXKKKKK0000KKOOKx,'okoc,'cldkOOKXXNNNXXXXXXKKKK0000kdkKKKKOdxxdxxxxxkkOOOOk:.'    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FREESTYLE is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
