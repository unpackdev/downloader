
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SaotFestival
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                        //
//                                                                                                                                        //
//    We are a collective of Palestinian artists and activists in the diaspora,                                                           //
//    who aim to mobilize around the culture and politics of the Palestinian                                                              //
//    question and intersectional struggles.                                                                                              //
//                                                                                                                                        //
//    This NFT auction raise will go 100% to support the festival, and the artists participating in it                                    //
//                                                                                                                                        //
//    Website: http://saotfestival.net                                                                                                    //
//                                                                                                                                        //
//                                                                                                                                        //
//     _     _____  _____  ____           ____  ____  ____  _____  _____ _____ ____  _____  _  _     ____  _       _      _____ _____     //
//    / \ /|/__ __\/__ __\/  __\__  /\ /\/ ___\/  _ \/  _ \/__ __\/    //  __// ___\/__ __\/ \/ \ |\/  _ \/ \     / \  /|/  __//__ __\    //
//    | |_||  / \    / \  |  \/|\/ / // /|    \| / \|| / \|  / \  |  __\|  \  |    \  / \  | || | //| / \|| |     | |\ |||  \    / \      //
//    | | ||  | |    | |  |  __/__/ // / \___ || |-||| \_/|  | |  | |   |  /_ \___ |  | |  | || \// | |-||| |_/\__| | \|||  /_   | |      //
//    \_/ \|  \_/    \_/  \_/   \/\/ \/  \____/\_/ \|\____/  \_/  \_/   \____\\____/  \_/  \_/\__/  \_/ \|\____/\/\_/  \|\____\  \_/      //
//                                                                                                                                        //
//                                                                                                                                        //
//                                                                                                                                        //
//    Berlin has always been a hub for cultural and political activism.                                                                   //
//    People from West Asia and North Africa have arrived in Berlin with fraught                                                          //
//    stories. Having made experiences in the wake of the past years in which they                                                        //
//    revolted in manifold waves of discontent and demanded freedom and dignity.                                                          //
//    There is a real thirst for a thriving cultural and artistic life that mirrors                                                       //
//    the languages, roots, and newly created practices of people from the WANA region.                                                   //
//     Within this wider picture Palestinian communities in Berlin, the biggest in Europe,                                                //
//    are completely marginalized from the city’s cultural life, politics and public spaces.                                              //
//    The collective space is further disrupted by the locally enforced fragmented geographies                                            //
//    of Palestinian communities worldwide.                                                                                               //
//    SAOT – The Palestine Solidarity Festival confronts the efforts of undoing these injustices                                          //
//    and contributes to the decades-long battles manifested through resistance and art.                                                  //
//    As struggles for justice, in a strongly networked globalized world, are intersectionality                                           //
//    intertwined and our identities are shaped by one another, a festival that centres around solidarity                                 //
//    reconnects the mutual longing of the diverse diasporic communities in Berlin.                                                       //
//                                                                                                                                        //
//                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SFC is ERC721Creator {
    constructor() ERC721Creator("SaotFestival", "SFC") {}
}
