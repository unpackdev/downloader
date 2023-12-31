
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MinimalKitten
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                               //
//                                                                                                                               //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,(@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@%,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,/@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@,,,@@@@@@@@@@@@@@@,,,@@@@@@@,,.@@@@@@@@@@@@@@@,,,@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@,,,,@@@@@@@@@@@@@,,,,@@@@@@@*,,,@@@@@@@@@@@@@,,,.@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@#,,,,@@@@@@@@@,,,,*@@@@@@@@@&,,,,@@@@@@@@@*,,,,@@@@@%,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,/@@@@@@@,,,,,,,,,,,,,&@@@@@@@@@@@@@@,,,,,,,,,,,,,%@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,/@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,@@@@@@@  ,,,@@@@@@@@  @@@@@@  @@@@@@  ,,@@@@@  @@@@@@  @@@@@@@  ,,,@@@@@@@@  ,,,,@@@@@@@  ,,,,@@@@@@  ,,,,,,,,@@    //
//    @@,,,,,@@@@@@@@  ,,@@@@@@@@  @@@@@@  @@@@@@@  ,@@@@@  @@@@@@  @@@@@@@@  ,,@@@@@@@@  ,,,@@@@@@@@@  ,,,@@@@@@  ,,,,,,,,@@    //
//    @@,,,,,@@@@@@@@@  @@@@@@@@@  @@@@@@  @@@@@@@@@ @@@@@  @@@@@@  @@@@@@@@@  @@@@@@@@@  ,,#@@@@@@@@@@  ,,@@@@@@  ,,,,,,,,@@    //
//    @@,,,,,@@@@@@@@@@@@@@/@@@@@  @@@@@@  @@@@@@@@@@@@@@@  @@@@@@  @@@@@@@@@@@@@@*@@@@@  ,*@@@@@ .@@@@@  ,@@@@@@  ,,,,,,,,@@    //
//    @@,,,,,@@@@@ @@@@@@@@ @@@@@  @@@@@@  @@@@@ @@@@@@@@@  @@@@@@  @@@@@ @@@@@@@@ @@@@@  ,@@@@@@@@@@@@@@  @@@@@@  ,,,,,,,,@@    //
//    @@,,,,,@@@@@  @@@@@@  @@@@@  @@@@@@  @@@@@  #@@@@@@@  @@@@@@  @@@@@  @@@@@@  @@@@@  @@@@@@@@@@@@@@@@ @@@@@@@@@@@  ,,,@@    //
//    @@,,,,,@@@@@  #@@@@  ,@@@@@  @@@@@@  @@@@@  ,,@@@@@@  @@@@@@  @@@@@  %@@@@  ,@@@@@ @@@@@# ,,,,,@@@@@@@@@@@@@@@@@  ,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@,,,,,,,,,,,,,,,,.,,,,,,,,,.,,,,,,,,,,,,,,,,,,,,,,,,,,..,,,,,,,,,,,,,,,,,.,,,,,,,,,,,,,,,,.,,,,,,,,.,,,,,,,,,,,.,,,,@@    //
//    @@,,,,,@@@@@@( ,,@@@@@@@@  ,,@@@@@@@  ,@@@@@@@@@@@@@@@@( @@@@@@@@@@@@@@@@  ,@@@@@@@@@@@@@@  ,,@@@@@@@@  ,,@@@@@@  ,,,@@    //
//    @@,,,,,@@@@@@( ,@@@@@@@  ,,,,@@@@@@@  ,@@@@@@@@@@@@@@@@( @@@@@@@@@@@@@@@@  ,@@@@@@@@@@@@@@  ,,@@@@@@@@@  ,@@@@@@  ,,,@@    //
//    @@,,,,,@@@@@@#@@@@@@@  ,,,,,,@@@@@@@  ,,,,,,@@@@@@& ,,,,,,,,,,@@@@@@  ,,,,,,@@@@@@  ,,,,,,,,,,@@@@@@@@@@  @@@@@@  ,,,@@    //
//    @@,,,,,@@@@@@@@@@@@/ ,,,,,,,,@@@@@@@  ,,,,,,@@@@@@& ,,,,,,,,,,@@@@@@  ,,,,,,@@@@@@@@@@@@@  ,,,@@@@@@@@@@@@@@@@@@  ,,,@@    //
//    @@,,,,,@@@@@@@@@@@@@@  .,,,,,@@@@@@@  ,,,,,,@@@@@@& ,,,,,,,,,,@@@@@@  ,,,,,,@@@@@@@@@@@@@  ,,,@@@@@@ @@@@@@@@@@@  ,,,@@    //
//    @@,,,,,@@@@@@& @@@@@@@@  ,,,,@@@@@@@  ,,,,,,@@@@@@& ,,,,,,,,,,@@@@@@  ,,,,,,@@@@@@  ,,,,,,,,,,@@@@@@  @@@@@@@@@@  ,,,@@    //
//    @@,,,,,@@@@@@& ,,@@@@@@@@ .,,@@@@@@@  ,,,,,,@@@@@@& ,,,,,,,,,,@@@@@@  ,,,,,,@@@@@@@@@@@@@@  ,,@@@@@@  ,/@@@@@@@@  ,,,@@    //
//    @@,,,,,@@@@@@& ,,,@@@@@@@@. ,@@@@@@@  ,,,,,,@@@@@@& ,,,,,,,,,,@@@@@@  ,,,,,,@@@@@@@@@@@@@@  ,,@@@@@@  ,,.@@@@@@@  ,,,@@    //
//    @@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//                                                                                                                               //
//                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Moods is ERC721Creator {
    constructor() ERC721Creator("MinimalKitten", "Moods") {}
}
