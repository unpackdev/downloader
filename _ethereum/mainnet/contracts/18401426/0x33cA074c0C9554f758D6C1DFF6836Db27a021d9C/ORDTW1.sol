// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ordinal Twins v1
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                      :55555:  :5555557    :55555:   555  :55:  :55    555555    :55                        //
//                     555:::555 :::::::555  :55::555  555  :555: :55  :55::::55:  :55                        //
//                     55:   :55        :55: :55   55: 555  :5555::55  :55    55^  :55                        //
//                     55:   :55        555  :55   55: 555  :55:55:55  :55    55^  :55                        //
//                     55:   :55 :55555555         55: 555  :55 55555  :55  5555^  :55                        //
//                     555   555 :55:  :555       :55: 555  :55  5555  :55    55^  :55                        //
//                      :55555~  :55:   :55: :555555   555  :55   555  :55    55^  :555555                    //
//                                                                                                            //
//                    :BBBBBBBBBBBB:  B:    :B           BB  B: :BBB       B: :BBBBBBBBBBB:                   //
//                          ~B         BB     B:       :B:   B: B: .BG     B: B:                              //
//                          ~B          .B:    :B     BB     B: B:   :B:   B:  :BBBBBBBBBB:                   //
//                          ~B            BB  B: B: :B:      B: B:     :B: B:            :B                   //
//                          ~B              BB    :B:        B: B:       :B:  :BBBBBBBBBB:                    //
//                                                                                                            //
//                                                                                                            //
//    ----                                                                                                    //
//    NOTICE:                                                                                                 //
//    This is v1 of this service. These are not for trading/sales/etc.                                        //
//    The NFTs that this creates are meant for display on platforms that                                      //
//    allow for displaying verified PFP NFT's on Etheum, allowing its                                         //
//    holder to display their Ordinal located on the Bitcoin Blockchain.                                      //
//    All holders of this are verfied to be the owner of the paired                                           //
//    ordinal at the time of verification.  We have yet to complete to                                        //
//    updating system to keep the nft updated with owner info.  So as it                                      //
//    stands,  this is just a way to view/display your ordinals on the                                        //
//    Ethereum Blockchain and any platform that allows it to be displayed.                                    //
//                                                                                                            //
//    *************DYOR!  DO NOT BUY ANY ORDINAL BASED ON THIS NFT**************                              //
//    **DO NOT use these as a way to verify ordinal ownership during sales                                    //
//    negotiations.  DO NOT make decisions on a purchase of ordinal(s) based                                  //
//    on these NFTs.  We are not responsible for any problems if you do.                                      //
//    Again, these are for display only, nothing else.                                                        //
//    ----                                                                                                    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ORDTW1 is ERC721Creator {
    constructor() ERC721Creator("Ordinal Twins v1", "ORDTW1") {}
}
