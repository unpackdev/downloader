
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Waterfalls
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    YrLvLvvvv7LvvvLvv7LLuvv7LvLvvvLvLvLvLvLvYvL7vvvvvvv7vvL7LvLvv7v7vvvvLvvvL7vvvvLvvvvvvvvvL7Lvv7L7vvvvvvL7L7L7vvL7L7Lvvvv7v7L7L7LvLvLvYvL7v7v7Lvvvv7LvYr    //
//    v:rririririririririir7rririririririrrrrririririririririririririririrrririririririririririririririririririririririririririririrrrrriririririririririrr:    //
//    LiL7v7v7vvL7v7vvL7v7v7LLs7v7v7LvvvLvvvvvv7v7v7v7vvLvvvvvvvLvLvv7vvv7vvL7v7v7L7v7vvv7v7v7v7vvvvv7v7v7v7v7v7v7L7L7v7v7L7v7LvvvL7v7v7v7v7v7vvLvL7v7vvvvLr    //
//    vrvv7v7vvv7v7vvv7v7v7v7v7YvL7v7v7v7v7v7v7v7v7vvv7v7v7v7v7v7vvv7v7v7v7vvLvv7v7v7v7v7v7v7v7vvvvv7v7v7v7v7v7v7v7v7v7v7vLL7vvv7v7v7v7v7v7v7v7vvv7v7v7v7Lvr    //
//    LiL7v7v7v7v7v7v7v7v7v7v7v7vLL7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7vvv7v7v7v7v7v7L7LvYYjY7r77v7v7v7v7v7v7v7vvv7vvv7v7v7v7v7v7v7v7v7v7v7v7v7v7v7Li    //
//    vrvv7v7v7v7v7v7v7v7v7v7v7v7v7Yvv7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7LvLvYsuJJv7i.57r77v7v7v7v7v7v7v7v7v7vvv7v7v7v7v7v7v7v7v7v7v7v7v7v7v7r    //
//    LiL7v7v7v7v7v7v7v7v7v7v7v7v777LvL7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7vvv7LvsJujJv7i:..   gBrr77v7v7v7v7v7v7v7v7v7vv77v7v7v7v7v7v7v7v7v7v7v7v7v7Lr    //
//    vr7v7v7v7v7v7v7v7v7v7v7v7v7v7v77vsv77v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7vvv7vvsjUsJ77::.. . .... 5BR7i77v7v7v7v7v7v7v7v7v7vvv7v7v7v7v7v7v7v7v7v7v7v7v7v7r    //
//    viL7v7v7v7v7v7v7v7v7v7v7v7v7v7v777vvY777v7v7v7v7v7v7v7v7v7v7v7v7vvL7Yvjs1sJ7i:::. ........:.. jBBQv:7777v7v7v7v7v7v7v7v7vvv7v7v7v7v7v7v7v7v7v7v7v7v7Li    //
//    vrvL7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7vvYvv7v7v7v7v7v7v7v7v7v7v7vvYYuJ1sYri:...  .i............. 7BgQBU:77v7v7v7v7v7v7v7v7v7vvv7v7v7v7v7v7v7v7v7v7v7v7vvr    //
//    Liv7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7vLL777v7v7v7v7v7v7vvYYJJusLri.... ...::.:i:::::::::.... 7BRDBB5ir777v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7Lr    //
//    vr7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7vvYv77v7v7v7LvYYuJjLvr::: . ....:.....r.......:.::::r: :BgDDQQbir7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7vvr    //
//    viL7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v777LLL7v7YYusJvLi:.... :...........::::..........:.... :BREDZQBgri777v7v7v7v7v7v7v7v7L7v7v7v7v7v7v7v7v7v7v7v7Lr    //
//    vr7v7L7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7vv2js7ri:.... ....::........:::...:......:::...... .BRDZDDQQB7ir77v7v7v7v7v7v7v7v7L7v7v7v7v7v7vvv7v7v7v7vvr    //
//    Liv7v7vvv777v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7vvLiii.  ....::.:.::.....::::.....i.....:::........  BBEDZDDRQBYir77v7v7v7v7v7v7v7v7v7v7vvvvv7v7v7v7v7v7vvLr    //
//    vrvv7v7v7vvv7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7Lv  .ir:....:i:::.:::::::.....:::::.:::............ QQMdDZDggQB1ir77v7v7v7v7v7v7v7v7L7v7v7v7v7v7v7v7v7v7vvr    //
//    Liv7v7v7v7v7L7v7v7v7v7v7v7v7v7v7v7v7v7v7v7vYv.....ir:..:......::......:::....::...........:... gBggEgEggRRBKii77v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7vvLi    //
//    vrvv7v7v7v7v7v7L7v7v7v7v7v7v7v7v7v7v7v7v7v7jr.......iri.......:....:::.......::..:.....:.::::. gBDMMDgbgMDgBEri77v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7vvr    //
//    vivvv7v7v7v7v7v7vvv7v7v7v7v7v7v7v7v7v7v7v7vJi.......:::::.....:.:::...........i.:...:.......:. KBDgEgggMQgMgQM7i77v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7Li    //
//    vr7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7vv1:.::...:::.::i:..i:..............:................ UBQEgZDgMZggQZBQL:77v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7vvr    //
//    LiLvv7v7v7v7v7v7v7v7vvL7v7v7v7v7v7v7v7v7v7LY. .:i:i...:::.iii:::..........:::.............:... LBMDZgZgDZgDMMgQBUi77v7v7v7v7v7v7v7vvv7v7v7v7v7v7v7v7vi    //
//    vr7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7vvJ.:::..:.....::..:i:::....:::::...:................ 7QQDDZDEMZggdYQgQBYr77v7v7v7v7v7v7v7v7v7v7v7v7v77777vvr    //
//    viv7v7v7v7v7vvv7v7v7v7v7v7vvv7v7v7v7v7v7v7YY:.....::...::.....::i:..:::......:................ iBRgZgZDggdRDURBDBur7v7v7v7v7v7v7v7v7vv777777v7LvsLJLJr    //
//    vr7v7v7vvv7v7v7v7v7v7v7v7v7v7vvv7v7v7v7v7vs7.......::.::.........7i:.........::............... :BQDDEgEgDZgBILXBQq:77v7v7v7v7v77777777vLvYYJLsvY7v7v7i    //
//    YiLvv7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7jr....:...:i:..........::...........:.......:.:.:.:. .BQRZZZgZgEgQ: .gBZirv7v777vrv7v7LLsYsYYLL7v7777777v7Li    //
//    vr7v777v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7LJi........::.......:.:::............::.:.:.:........ .BBZRDZEDgDEQbj:PBBir7v7vvLLsYsLYvv7v777v7v7v7v7v7v7vvr    //
//    vivvL7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7vvL7v7u:........:...:::::....::..........:............:.:.. BQgERgDEMEDgBBBRRQv7sYsvYvv7v7v77777v777v7v7v7v7v7vvvi    //
//    vr7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7vvLJ.......:i.:::.:.....::..:::.....::..........:::....  QBgZdggDMgdgZgEggQLr7v77777v7v7v7v7v7v7v7v7v7v7v7v7vvr    //
//    viL7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7vYJ...:::.::.........::......::.::..:.....:.:.:........ gBREDEggZgDDgggZRQ1i77v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7Li    //
//    7rvv7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7Yv..:.....:.......:::.......:.....::..:.:............. dBQBgDDREDMgdMDggQ5i777v7v7v7v7v7v7v7v7v7v7L7v7v7v7vvr    //
//    viv7v7v7v7v7v7v7v7v7v7v7v7v7vvv7v7v7v7v7vs7 ........:....:::.........:.....:....:. :........... dBRdBRREggMgEggDMREi77v7v7v7v7v7v7v7v7v7v7v7L7v7v7vvLr    //
//    vrvv7v7v7v7v7v7v7v7vvv7v7v7v7v7v7v7v7v7vvji.........:..:::...........:.....:..:..:..............i  .LBggEMggDDgggBgrrv7v7v7v7v7v7v7v7v7v7v7v7v7v7v7vvr    //
//    viv7v7v7v7v7v7vvv7v7v7v7v7v7v7v7v7v7v7v7Lj:..........::..............:....:...:................ :    RBZDEMDMEgggQQrr7v7v7v7v7v7v7v7v7v7v7v7v7L7v7v7Li    //
//    vr7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7vv1:.::::.:.:.:...............:...::......:...... ......:::.. rBgZDZRgggRgRQvrv7vvv7v7v7v7v7v7v7v7v7v7v7v7v7v7r    //
//    LrLvv7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7Ls....:.:.:..i::......:.:...::..:::.:..   . ..iiri:..::::... jBRDZgggEgMgRBur7v7v7v7v7v7v7v7v7v7v7v7v7v7L7v7vi    //
//    vrvv7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v77777vvs.........:::.i::.:.:.:.:.i.::......:.....:.:rri.  .:.:.:.. 5BBgDMBMDEgdgBXiv7v7v7v7v7v7v7v7v7v7v7v7v7v7L7vvr    //
//    viv7v7v7vvv7v7v7v7v7v7v7v7v7v77777v7vvYv1L........::..:..............:........ 2Birrr      ...r::.   rBgBBB7ZgZggEQEirv7v7v7v7v7v7v7v7v7v7v7v7v7vvv7Lr    //
//    vrvv7v7v7v7v7v7v7v7v7v7v777v7vvLvYLsLYvsj7 ......::....:...........::......... iBU ii7.  ..:rL7i.... .BBQb. dBDQggRgi77v777v7v7v7v7v7vvv7vvv7v7v7v7v7r    //
//    viv7v7v7v7v7v7v77777v7vvYvsvYLYvv7v77777ji.....::.....:.............:......     QB. irJi.:r7Yi. .... .R7... bBREMZRQrrv7vvv7v7v7v7v7v7v7v7v7v7v7v7vvLr    //
//    vr7v7v7v77777v7vvsvYYYvYvv7v77777v7v7v7vJ: ..::.......::.......... .         ...IBB..irJr...         :.  :..gBQEZMgBvr7v7vvL7v7v7v7v7v7v7v7v7v7v7v7vvr    //
//    viv777v7vvLLYvYvY7v7v7v777v7v7v7v7v7v7vvu:.:::........:....        ...i71KgQBBBQBQBB.   ::      .:v2EBj ir.iBgQDDggB1iv7v7v7L7v7v7v7v7v7v7v7v7v7v7v7Lr    //
//    LrvYvsLLvY7v7777777v7v7v7v7v7v7v7v7v7v7vs:..:.....         ..:ru5ERBBBQBQBBBBBQQQQQBS:ii:v7jSMQBBBQBBB:.r: LBMgMEMgB2i7v7v7v7v7v7v7v7v7v7v7v7v7vvv7vvr    //
//    srLvv7v7v777v7v7v7v7v7v7v7v7v7v7v7v7v7vvY . .      .:iJ5dMBQBBBQBBBQBQQQQRQRRMRMQQQQBBBBBQBBBBBBBQQQBi .   sBDgggEMQbi77v7v7v7vvv7vvv7v7v7v7v7v7v7v7vi    //
//    vi777v7v7vvv7v7v7v7v7v7v7v7v7v7v7L7L7vvLr..:iu1bgBBBBBBBQBBBBQRQQQgRDRRMgMgMgRgMgMgRQBQBQQQQRQMQRQMQBr r7UbBMDZggZgQDr7v7v7v7v7vvL7v7v7v7v7v7v7v7v7vvr    //
//    LiL7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v777v7v7v5BBBBBBBBBBBRRRQMQRQQQRQMQRQRMgRgRMRgRgQgRMQgRMQgRMQgRgRgMMBQBBBQBQQgRDgZgQQrr7v7v7v7v7v7v7v7v7v7v7v7v7v7vvvr    //
//    vrvv7v7v7v7v7v7v7v7L7v7v7v7v7v7v7v7v7v7v77r7LqMBQBQQRQMMMQMQgRMQgRgQRQMRRRgQgQMRMRgQQRgMMQgRgMMQgMMQMQQQRQgMgRRMDgdQBvi77v7v7v7v7v7v7v7v7v7v7v7v7v7vvr    //
//    vrv7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v77rriir1bBBBBBQQgMDggMgMgMgMgQgMgMgggRgMgRRMgggMgMgMgMgMgMgQRRMRMRgRRRRQMggBJi7v7v7v7v7v7v7L7v7vvv7v7v7v7v7Lr    //
//    vrvvvL7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v777riiiv2gBBBBQQRQgMgggQgMRQMQRRgQRQMRQRMQMMgMgRgMgggRRQMRRQMQRQQBQBBBBBBbiv7v7vvv7v7v7v7v7v7v7v7v7v7v7vvr    //
//    viv7v7v7vvv7v7v7v7v7v7v7v7v7vvL7v7v7v7v7v7v7v7777r7iiirYqRBBBBBQQQQRQMRgMgRMQgggMgMgMgRRQQQRQRQQQQQQBQBBBBBBBQBQQDZPdj77v7v7v7v7v7v7v777v7v7v7v7v7v7Lr    //
//    vr7v7v7v7v7v7v7v7v7v7v7v7v7v777v7v7v7v7v7v7v7v7v777777rrir7IgBQBBBRRMQgQMQRMRQMQgQQQQQQBQBBBBBBBBBBBQREdKSuJ77rrii:ii7777v7v7v7v7v7vvv7v7L7v7v7v7v7vvr    //
//    Liv7v7v7v7v7v7v7v7L7v7v7v7v7v7v7v7v7v7v7v7v7v7vvvvvvv7v77rriirYXQBBBBQQQBQQQBQBBBBBBBBBBBMMEPS2sL77rrii:iiiirrrr7r7777vvv7v7v7v7v7v7v7v7v7v7v7v7v7v7vr    //
//    vrvv7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7L7v7v7v7v7v7v77777riii7uZBBBBBBBBQQMDbP5IYL7riiii:iiiirr7r777777v7v7v7v7v7v7v7L7v7v7v7v7v7v7v7v7v7v7v7v7Lvr    //
//    viL7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v777v77riirLS2uLvrrii:i:i:rirrrr77777777v7v7v7L7v7v7v7v7v7v7v7v7vvv777v7v7v7v7v7v7v7v7v7v7Li    //
//    vrvv7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7L7v7v7v7v7v7v7777rriiirirrrr7r7777v7L7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7vvL777v7v7v7v7v7v777v7v7vvr    //
//    LiL7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v777v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7vvv7L7v7vr    //
//    vr7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7vvv7v7v7v7v7v7v7v7v7v7v7v7v7vvv7v7vvL7v7v7v7v7v7v7v7v7vvr    //
//    LiL7v7v7v7vvv7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7vvv7v7v7v7v7v7v7v7v7v7v7v7v7v7vvv7v7v7v7v7v7v7v7v7v7vvv7v7v7v7v7v7v7vvvr    //
//    vrvv7v7v7v7v7v7v7v7vvv7v7v7v7v7v7v7vvv7v7v7v7v7v7v7v7v7v7v7v7v7vvv7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7vvvvv7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7v7vvr    //
//    vivvv7v7L7v7v7v7v7v7v7vvLvvvv7v7v7v7v7v7LvvvL7vvv7v7v7vvvvv7v7v7v7v7v7vvv7vvL7v7vvL7v7v7L7v7v7v7v7v7v7v7L7v7v7v7v7v7v7L7v7v7vvv7v7v7v7Lvv7v7v7vvv7v7Lr    //
//    vrvL7v7L7LvLvvvLvLvvvvvLvvvvvLvvvLvvvv7L7LvvvYvLvY7v7L7vvvvLvLvLvv7vvL7L7LvYvLvv7LvvvLvvvLvLvLvLvLvL7vvLvvvvvLvL7v7LvLvvvLvv7vvLvL7vvvvvvYvvvYvLvLvYv7    //
//    Y:rrrrrrrrrirrrirrrirrrrrrrrririrrrrrrrrrrrrrrrrrrrrrrrrrrririrrrrrrrrrrrirrrrrirrrrririrrririrrrrrrrirrrirrrrrrriririrrrrrrrrrrrrrrrrrrrirrrirrrrrrr:    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WTRS is ERC721Creator {
    constructor() ERC721Creator("Waterfalls", "WTRS") {}
}
