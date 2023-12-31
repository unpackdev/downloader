// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MUSKETON.V1
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//                                                                                       //
//    SMART CONTRACT BY: MUSKETON                                                        //
//    PLATFORM TOOL: MANIFOLD.XYZ                                                        //
//    SMART CONTRACT NAME: MUSKETON.V1                                                   //
//    SMART CONTRACT SYMBOL: MV1                                                         //
//    SMART CONTRACT TYPE: ERC721                                                        //
//    FIRST TIME IN USE: 2023                                                            //
//                                                                                       //
//    DIGITAL SUPPORT BY:                                                                //
//    ARTIST PROOF STUDIO (WWW.ARTISTPROOF.BE) (CONTACT: THOMAS DE BEN)                  //
//    _                                                                                  //
//                                                                                       //
//    CONTRACT PURPOSE:                                                                  //
//    1. THE CONTRACT HAS ITS PURPOSE TO REGISTER (DIGITAL) ARTWORKS                     //
//    BY BELGIAN ARTIST MUSKETON AND MAKE ARTWORKS READY FOR DISTRIBUTION.               //
//                                                                                       //
//    2. TOKENS DEPLOYED ON THIS CONTRACT GIVE TOKEN OWNERS CERTAIN RIGHTS ON            //
//    THE USE OF BOTH THE PHYSICAL AND DIGITAL ARTWORK.                                  //
//                                                                                       //
//    3. TOKENS DEPLOYED ON THIS CONTRACT ALWAYS BELONG TO A PHYSICAL VARIANT.           //
//    BOTH ALWAYS MATCH TOGETHER AND MAY NOT BE DISTRIBUTED OR SOLD SEPARATELY           //
//    AS DESCRIBED IN THE TOKEN SPECIFIC DOCUMENT ATTACHED TO THE NFT OF THE ARTWORK.    //
//    _                                                                                  //
//                                                                                       //
//    PLEASE CONTACT THE ARTIST IN CASE OF DOUBT ABOUT THE AUTHENTICITY                  //
//    OF THE CONTRACT AND ITS TOKENS.                                                    //
//                                                                                       //
//    MAIL: INFO@MUSKETON.COM                                                            //
//    PORTFOLIO: WWW.MUSKETON.COM                                                        //
//                                                                                       //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////


contract MV1 is ERC721Creator {
    constructor() ERC721Creator("MUSKETON.V1", "MV1") {}
}
