
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hyume
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                             //
//                                                                                                             //
//    .................................---------------------:::::::::::::::::::::::::::://////////////////     //
//    ..................................-------------:::::::::::::::::::/::::/:::::::::://////////////////     //
//    ...................................----:::://+++///:::::::::::::::::::////://///////////////////////     //
//    ..................................-:/+oossyyyyyhhhys+++/:::::::::::::::::///////////////////////////     //
//    ................................-/+oosyhdmmmmmmmmNmmddhyys/:::::::::::::::::////////////////////////     //
//    ..............................:/++osdmmmmNNNNNmNNNNNNNNNNNms/:::::::::::::::::://///////////////////     //
//    .............................:+oshmNNNNNNNNNNNNNNNNNNNNNNNNNmdhs+/:::::::::::::::://////////////////     //
//    ............................/shmm$de$NNNNNNNmmmmmmmNNNNNNNNNNNNNNNmh+:::::::::::::::::///////////////    //
//    .........................-:odmNNNNNNNNmdhyooo++ooossyhdmNNNNNNNNNNNNy/::::::::::::::::::////////////     //
//    .......................:+yhmNNNNNNNmdyo+///////////+++ooshdNNNNNNNNNNNy:::::::::::::::::::::////////     //
//    .....................-/shhmNNNNNNmho+//::::::::::////++++ooshmNNNNNNNNNd/::::::::::::::::::::://////     //
//    ```````..............+yhymNNNNNNho+/::--::----:::://///+++oosshNN$CeN$MMy+:::::::::::::::::::::::://     //
//    `````````.........../yyyNNNNNNNy+//:----------:::://////+++ooosdNNNNNNNMys+/::::::::::::::::::::::::     //
//    ``````````.........-shhmNNNNNNho/::::-----------::://////+++oosydmNNNNMNyo++::::::::::::::::::::::::     //
//    ```````````......-./mmNNNNNNNmy+/:::-----------:/+oossssoo++oooyhdmNNMNNso+os///::::::::::::::::::::     //
//    ```````````.......-hmmNNNNNNNmy+/:----.....--:+shdmmmmmdddhysoosydmNNNNNdosyy+////::::::::::::::::::     //
//    ````````````....-+hmmdmNNNNNNmy+:----......-/+syhhhyooo+ossyhhsooydNNNNNNNddh/:::/::::::::::::::::::     //
//    ````````````...:yyhmmmmmNNNNNNho/////:------:+ooo+//::////++oyysooshNNNMNmmmdhysso//::::::::::::::::     //
//    ```````````...+yoohmmNNmNNNNmNmyyhhhs+/::---:/++++++//+ooso+++ooo+osdNNMMNNy+oyo++oo+/::::::::::::::     //
//    ``````````..-+hsoshdmNNmNNNNmNNmNmdyooo+:--://+/+osshhddhdhs+++++++osdNNMNNms++sys+/+o+:::::::::::::     //
//    ``````````..+hssoyhdmNmmNNNNmNNmyo+//+oo:--:///++yyosyyyyso+//////++osmNNmmNmho++syo:/o+::::::::::::     //
//    `````````..:yhssyhhdmmddNNNmmNmho+//+os/---://:://///////::::://///++osmmhhddmds//+ys:+s::::::::::::     //
//    `````````..ohyshyydddddmmNNddmdhysshhds-..-:////::-----------:::///+++oymysshhmds+:+yo/s::::::::::::     //
//    ````````..:ohyyyyddhddddmNmdmdddddhdhs:.``.-::///:......------::://+++osdhooshdd+o+:+hs/::::::::::::     //
//    ````````./+/ohdyydyyddmmmmmmmmddmhso+/:..-:/+++://........----:::://+ooydmo/sdhm++++/d+:::::::::::::     //
//    ```````:+//oohdhdhshdmmmmmNNNmddyo/:-:+so//yyhy//o-........---::::/++ooymmy/sNhhhoshss/:::::::::::::     //
//    ``````.-/oo/+smddyhddm$tr4$mNdho:-...+sy++/:-:++:--.......--:::::/+osshmmyoomdyd/:o::::::::::::::::      //
//    `````.-:/+://+dmdyhhdmmNNNNmmNdy/-..``-oys/-+++osooo+//-...--::://+osyhdmmy+symmh+/+::::::::::::::::     //
//    ``````.-:-.::shmhosydmmmmmmmmNhs:-..`.-ydy+:+o/://+ssyhy+:---:::/+osyhhdmmyodhmmy++:::::::::::::::::     //
//    ```````-::-:+oddo/shmmmmmmddmNds/-...:yhs+-----:://++oshho:--:///oosyhdmmNNhmdhso//:::::::::::::::::     //
//      ````.--::/:sdy/oydmmmmmNdmNNNy/:-./hdo++/++++++oosoo++os:--:/+ossyhhdmNNmddmdss+/:::::::::::::::::     //
//        ``.--//:+hh++shdmmmmNNmmmNNms/:-smhyyo+//::--::::----:-.-:+osyyyhddmNNNNmmmhhs+/::::::::::::::::     //
//        ```-/-.-sho/+yhhdmmmNNmNmmNNms/-/ysoo/--......-------...-:/osyhhhddmmNNNmmmmdyoo+//:::::::::::::     //
//        ```::`.+hy//yhddddmmNmNNmmNNNmy/.--:/:::/:/++/---..----:://+osyhhdmmdmNNNdhdmmyooo+////:::::::::     //
//         ``:..:yy+-ohdddhhmmmmmmmmmNNNmy:--:///+so+o//-.....--:://+++ssydmmdyyMNNMmyhmdyyoooo///////////     //
//         ``:..ooo-:sddhdyymmmmmmmmmNNNNms::::--//:--...`....--://+osyyhmNmmhssmMMMMmdddyyhysss//////////     //
//         ``-.-+oo.osddhdsdmhdmddmmmNNNNNdo++:---..``````...--:/+syhdmmmNNmhsoohNNNMNNNmy+/osyyy/////////     //
//        ```.::/+o-oyddhdymhhdmdhhmmmNNMNNdyyo/::-````..--:++o+oshdmmmmmmhyso+osNNNNNNNNms////ydo////////     //
//           `:///s+/yhmdhydhdmmmdddmmmNNNNNmmhsyo+:..-:/++oshhhhdmmNmmdysso++++syNNNNNNNNNs///yys+///////     //
//           ``+++os-ssmdsdmmmmmmmmmmmmNNNNNNNNmddyho++oyyhhdmmNmmNmdhysoo+++/++osyNNNNNNNNNo/osy+////////     //
//           ``-o+/+/ohdmdmmmmmdmmNNNNmmNNMNNNNNNNmNmmddmmmNNNNmhyysssoo+//////+o+omNNMNMNNNNhhs+/////////     //
//           `.--oo/sshhmmmmmmmmmNNNNNNmNNNNNNMMNNNNNNNNmmmdhyssoooooo+//::////++/+NNNNNNNNMNNNhs+////////     //
//           .-../soysydmmmmmmmmNNNNNNNNNNNmmmmNNmmmdddhhysssooooo+++//:::::://++/oNNNNNNNNMNNNNNmdyo+////     //
//          `:.`./hysyhdmmmmmmmNNNNNNNNNMNNNNNmmNmmddhhyysysoooo++///:::-:::://///dNNNNNNNNMNNNNNNNNNmdyoo     //
//         `.-``-odsyhdmmmmmmmmNNNNNNNNNMNNmmNmNNmddhhyyssssoo+++//:::---::::::::yNNNNNNNNNMNNNNNNNMNNNNNN     //
//         ``..`/hyyhdmmmmmmmmmmNNNNMNNNNNNNmmmNNdhhhhhyysso++///:::-----::::--:oNNNNNNNNNNNNNNNNNMNNNNNNN     //
//       `   `./sdhmmmmmdmmmNNNmmNNNNNNNNNNNmmmNNmsysssooo++//::::------:::----+mNNNNNNN$LIZE$NNNNNNNNNNNN     //
//         ``+yddmmmmmmmmmNNNNNNNNNNNNNmNNNNmmNmNNhoo/////::::-------..--:--..omNNNNNNNNNNNNNNNNNNNNNNNNNN     //
//         .ydddmddmddmNNNNNNNNNNmNNNNNmmmmNNmmmmNNh+:-.....-..........----.-yNNNNNNNNNNNNNNNNNNNNNNNNNNNN     //
//        .sddddddmmmmmNNNNNNmmNmmNNNmmdmdmmmmmmmNmmd/..```````````````....omNNNNNNNNNNNNNNNNNNNNNNMNNNNNN     //
//      .:ydddhddmmmmmNNNNmNmNmmmmmmdmmddmdmddmmmNNNmmo-````````` `````..odNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN     //
//     -oddddmmmmmmNmNNNN$whatsthepassword$mmdNmhmdmmdhmNmNNNmNd/```````    ``:ymNNNNNNNNNNNNNNNNNNNNNNNNN     //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HME is ERC721Creator {
    constructor() ERC721Creator("Hyume", "HME") {}
}
