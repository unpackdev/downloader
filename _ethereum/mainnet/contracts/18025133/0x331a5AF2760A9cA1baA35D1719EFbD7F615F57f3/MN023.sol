// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mr.Noise023
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    vvccvccccvvvvvvvvcccccccccccccccccccccccccccccccccvvvcccvcccvvvvvccvccccccvccccccccccccccc    //
//    vcvvvcvcccvvvcccccccccccccccccccccccccccccccccccccvcccvvcccvcccccccvvcccccvvvcccvccccccccc    //
//    cccvvccccvcccccccccvccccccccccccccccccccccccccccvccccvcccvvvcvvccccvvcvvvcvvccccccvccccccc    //
//    cvccvvvcccccvccvvccvcccccccccccccccccccccccccccccvvcccvccccvvccvvcccvvccvvvvcvcccccccccccc    //
//    vccvccvvcccvvcvvvccvcccccccccccccccccccccccccccccccccccccvcvvccccccccvvvvcvvcvccccvccccccc    //
//    vvcvcvvcvcvccvvvvccccccccccccccccccccccccccccccccccccccvcvvcvvcccccccvvccccvvcvccccccccccc    //
//    vcvvccccccvvvvvvvvcccccccccccccccccccccccccccccccccvcccccvvvvvcccccccvvccvcvvvcccccccccccc    //
//    vcvvcccvccccvvcvvvcvvcvcccccccccccccccccccccccccvvcvcccccvvvccccvcvcvcccvcvcvcvvvcvccccccc    //
//    cvcccccvvvcccvcvcvccccvcccccccccccccccccvcvz*****zzcvvcccvvvcccccvcccvcccvcvccvvvvcccccccc    //
//    vvcvvvvvvvvccvvvvvcvcccccvccccccccccccccz#W##******#####*cvcvvvvcvvvcvccvccccvvvvccvcccccc    //
//    cvcccccccvvvvvcvvcccccvcccccccccccccc*MM*cvvvvvvvvvvvvcc*M#cvvcvvcvvvccccccvvvvvvvvccccccc    //
//    cvccvccccvccvccccccccvccccccccccccc*WW#ccvvvvvvvvvvvvvvvvc*M*cvvvcvvcccccccccvvvvvvccccccc    //
//    vvvvvccccccccvccvvvvccvccvccccccczWW#***zczccvcvvvvvvvvvcvvcMW*vvvcccvvvccvcvvvcvccccccccc    //
//    vvvcvccvccccccccvvcvvvvccccccccc#WWzccccc***#*#z**z*z*zz#zz*zMWMccvvccvcvvvvvvvccccccccccc    //
//    ccvvccccvvccccvccccccccccccccccWWWzzcccccccccccczzczzzzzzczzc*WWWcccccccccvcccvcvccccccccc    //
//    vcvvccvvvvvccvvcccvcccccccccccW&WMzzcccccccvvcccccccccccccccccWWWMvccvvccvccccccccccccvccc    //
//    vvccvvvvvvcvvcvvcccvcvccvvccv#W&W&M*zccccccvccvvvvvvvvvvccccccWWWWzvcccccvvvcvcvvvvvccvcvc    //
//    vcccvvvvvvvvuvcvccvvcccvvvcvcWWWWWWW#zzzczccccccccccczzzzzzcccMWWWMvvccvvccvcccvcvvvcccvvv    //
//    vvcvvvcvvvvcvvcvvcvcvvvccccvzW&WWWWWWW*#WWWWWW#***WWWWMW#*zccvMWWWWcccccccccvvvvvvvvcvcvvc    //
//    ccvvvvvvvvvcvvcvcvccccccvccc*WWWWWWWWWWWWufMWWW##*WWWWMMMzzccvWWWWW*vcvcccvcvvvvvvvccvvvcc    //
//    vccvccvvvvvvvvvvvvvvccvvvccc#WWWWWWW#MWWWMMWWW#*zzzMWW##*zzzczWWWWWMvvvvvvcvvvcvcvvvvcvvvc    //
//    ccvcvvvvvvvvvvcvvcvcvcvvccvv#WWWWWWWWz*#MWMM#**zccczzccvcz*W*#WWWWWWcvcccvcvvvvcvvvcvvcvcv    //
//    ccccvccvvvvvvvvvvccvvccccccvWWWWWWWWWW#cvvcz***cvvczzcccczWW*MWWWWWW*vvvvvvvvvvvvvvvvvcvvv    //
//    cccvvvcvvvvvvvcccccccvcccvczWWWWWWWWWWWWWMM**zMM##MW*zzz*#WW*WWWWWWWMvvvcvvvvvvvvvvvvvvvvv    //
//    ccvcvccvvvvvvvvvcvvcccvvvvv#WWWWWWWWWWWWWWW#*z#WWWWMzz**WWWM#WWWWWWWWcccvvvvvvvvccccvcvvcv    //
//    cccvccvcvvvvvvvvvvvccvcvcvcWWWWWWWWWWWWWWWWWM**MWWWM#**#WWW#WWWWWWWWWcccvvvvvvcccvvcvvcccv    //
//    ccccvvcvvvvvvvcvvvcccvvcvv#WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMWWWWWWWWWW*ccvvcvcvccccvvvvvvvv    //
//    cvcvvvcvvvvvvvvvvcvvvvvvvvWMWWWWWWWWWWWWWWWWWWWWWWWWWWWWMMWWWWWWWWWWWMvvvccvvccccccvvvvccv    //
//    cccuvvvvvvvvvvcvvvvvcvvvc##WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWcvcccccvvvvcvvvvccvv    //
//    cvcccvccvvvvvvvvvcvvvvcvzzWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWcvccvvccvvvvvvvvvccc    //
//    ccccvccvvccvvvvvvvvcvvcvvMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWvvvcvvcvvvvvvcvvvvvc    //
//    ccccccvvcvcvvvvvvvvvvvvv#WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&cvvvvvvvvvvvvvvvvvvc    //
//    cccccccvcccccvvvvvvvvvv#WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMvvvvvvvvvvvcvcvcvcc    //
//    ccccccccvccvcvvcvvvvvcMWWWMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWzvvvvvvvcvccccvcccv    //
//    ccccccccccvvvccvvcvvc*#WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMvvvvvvcvvvccccvccv    //
//    cccccccccvvvvccvvvvvcMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWzvvvccvcvccccccccv    //
//    ccccccvccvccvvccccv*WWWWWWWWWWWWWWWWWWWWWWW&WWWWWWWWWWWWWWWWWWWWWWWWWWW#*vvvcvvcvccccccvcv    //
//    ccccccccccvccccvvv#WWWWWWWWWWWWWWWWWWWWWWWWW&WWWWWWWWWWWWWWWWWWWWWWWWWWWzcvvvvvvvvvccccccc    //
//    cccccccccvcccvvcv#MWWWWWWWWWWWWWWWWWWWWWWW&WW&WWWWW&&WWWWWWWWWWWWWWWWWWWWcvcvvccvcccccvvcc    //
//    ccccccccccccvcvv*#WWWWWWWMWWWWWWWWWWWWWWWWWW&WWWWWWWWWWWWWWWWWWWWWWWWWWWWMvcvvcvcvvcccccvc    //
//    ccccccccccccccvcMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWcvccvcvccccccccc    //
//    cccccccccccccc*WWWWWWWWWWWWWWWWWWWWWWWWWWWW&WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWzvccccvccccccvcc    //
//    cccccccccccc*WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMcvvvcvvcccccccc    //
//    cccccccccc*WWWWW&WWWWWWWWWWWWWWWW&WWWWWWWW&WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWzvvvcccccccccc    //
//    ccccccccc#WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&WWWWWWW&W&WWWWWWWWWWWWWWWWWWWWWWWWW#vvvvcccvvvcc    //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract MN023 is ERC721Creator {
    constructor() ERC721Creator("Mr.Noise023", "MN023") {}
}
