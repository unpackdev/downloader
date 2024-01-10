
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sleep Experiment 수면 실험
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//    Sleep Experiment 수면 실험                                          //
//                                                                    //
//    Discoverer : 최형범 (崔衡範) (HyungBeom Choi)                         //
//    Nationality : Republic of Korea (대한민국)                          //
//    Date of Birth : May 27, 1994                                    //
//    Discovery through Intuition. Discovered on October 31, 2015.    //
//    직관을 통하여 발견한 이론. 발견 일자 2015년 10월 31일. 당시 만 21세.                  //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract SLEXP is ERC721Creator {
    constructor() ERC721Creator(unicode"Sleep Experiment 수면 실험", "SLEXP") {}
}
