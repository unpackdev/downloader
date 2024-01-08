// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./spriteStruct.sol";


contract spriteImage   {
    
    enum Part {Trunk,Mouth,Head,Eye,Tail,ColorContainer}

	bytes constant private PartFaceData =hex"822bd8d94a29030224555606942aaac1928555584a50aaab0c6e1555605555605555605555630940005400";
	
	
    mapping(Part=>mapping(uint=>bytes)) private PartData;
    mapping(uint256=>uint8[2]) private  SkinData;
	
	
    
	constructor(){
	    PartData[Part.Trunk][0] = hex"822bd8d95c6ba3012055581840aab05a01554a0451281144a1c122a8d10c9155689cc8d2840d00b000691000";
        PartData[Part.Trunk][1] = hex"852bbbd83533905c6ba301201249340c201249341680124922d008241168081210b43824124836886486db6e413990e46c08039000dc000034880000";
        PartData[Part.Trunk][2] = hex"852bc2d81d169e5c6ba301201249340c201249341680124922d008241168081210b43824124836886486db6e413990e46c08039000dc000034880000";
        PartData[Part.Trunk][3] = hex"852bc1d839329d5c6ba301201249340c201249341680124922d008241168081210b438241248b6886486db6e413990e46c08039000dc000034880000";
        PartData[Part.Trunk][4] = hex"852bc7d883589d5c6ba301201249340c201249341680124922d008241168081210b438241248b6886486db6e413990e46c08039000dc000034880000";
        PartData[Part.Trunk][5] = hex"852b65d8c79d5e5c6ba301201249340c201249341680124922d008241168081210b438241248b6886486db6e413990e46c08039000dc000034880000";
        PartData[Part.Trunk][6] = hex"852b5dd8cea3325c6ba301201249340c201249341680124922d008241168081210b438241248b6886486db6e413990e46c08039000dc000034880000";

        PartData[Part.Mouth][0] = hex"802b639ee11800";
        PartData[Part.Mouth][1] = hex"81972b5364e1001d17f8";
        PartData[Part.Mouth][2] = hex"822bbbb463a111820006630b631120";
        PartData[Part.Mouth][3] = hex"80966b9ae080";
        PartData[Part.Mouth][4] = hex"81d02b5b5ef2070140";
        PartData[Part.Mouth][5] = hex"802b6b9ce0a0";
        PartData[Part.Mouth][6] = hex"802b6362e1ad00";
        PartData[Part.Mouth][7] = hex"80b46b9cf11800";
        PartData[Part.Mouth][8] = hex"8156b4639ef10c2b80";
        PartData[Part.Mouth][9] = hex"81902b639ee11b00";
        PartData[Part.Mouth][10] = hex"812bac639ef1881e20";
        PartData[Part.Mouth][11] = hex"80965b62e180304400";
        PartData[Part.Mouth][12] = hex"842bd873c8d94b6712082db269250c824924936c80000248";
        PartData[Part.Mouth][13] = hex"842bd8c897d94b67120809932d98641249249b6400001240";
        PartData[Part.Mouth][14] = hex"81d7d96b9cf11980";
        PartData[Part.Mouth][15] = hex"81815653270211380a8c05e783c070";
        PartData[Part.Mouth][16] = hex"862bb4d4cdc778a253a95203100bc0000000434090982485b0024e001ca86ec114c4c28880";
        PartData[Part.Mouth][17] = hex"822b56814aef32868406e02000000416b46aa6510f1c4d4cc8226289694058082e18a506c18a3e0400";
        PartData[Part.Mouth][18] = hex"822b585f4aef32868406e02000000416b46aa6510f1c4d4cc8226289694058082e18a506c18a3e0400";
        PartData[Part.Mouth][19] = hex"822b97c24aef32868406e02000000416b46aa6510f1c4d4cc8226289694058082e18a506c18a3e0400";
        PartData[Part.Mouth][20] = hex"822ba2cd4aef32868406e02000000416b46aa6510f1c4d4cc8226289694058082e18a506c18a3e0400";
        PartData[Part.Mouth][21] = hex"822b5a604aef32868406e02000000416b46aa6510f1c4d4cc8226289694058082e18a506c18a3e0400";
        PartData[Part.Mouth][22] = hex"822b161d4aef32868406e02000000416b46aa6510f1c4d4cc8226289694058082e18a506c18a3e0400";
        PartData[Part.Mouth][23] = hex"83ac2bba562adef1800300b81a2b276035c0a8";
        PartData[Part.Mouth][24] = hex"82812b722a1d1180202900580800cdaabd6d309aac7cd2cd1ad5371aa8";
        PartData[Part.Mouth][25] = hex"832bcec7565baf42021014461725120c278155698910d5c5581f810d058a2400";
        PartData[Part.Mouth][26] = hex"832bbb90565baf42021014461725120c278155698910d5c5581f810d058a2400";
        PartData[Part.Mouth][27] = hex"842b9c72ac785bab228410164800000010d014ca910000000000";

        PartData[Part.Head][0] = hex"822bd8d949287203000001942aaac31620aab12813c0aab0";
        PartData[Part.Head][1] = hex"822bd8d948a8720100610862440001250aaab0c68055587f02aac0";
        PartData[Part.Head][2] = hex"822bd9d8386c7201200610041068374521522a51a8628343a429212051250a0a8e503195caaa00";
        PartData[Part.Head][3] = hex"822bd8d950287282002000c10848421620a87122a0c89d2320c8c92320c8f74320ca2c82aaaa00";
        PartData[Part.Head][4] = hex"822bd8d9482a8282002800e10858421a20a88922a0c8bd2320c8f22320aa02a93d42aaaa5d40aaa9a422";
        PartData[Part.Head][5] = hex"832bcea3d840ee930208016100444150d082a20185a45330d2835001548347fe54944212d8649880360200";
        PartData[Part.Head][6] = hex"842bd8d3c1d948687206004100401b609a682580024920c28124924c0f2c1009249824809700924980";
        PartData[Part.Head][7] = hex"832bd7ac8138ae83051800026601fff808ce155555619c232b34d540aaaaacb158e26a955a341800000000";
        PartData[Part.Head][8] = hex"832b1d6b3a386882871801338550204955522d514ad28ed454d4e47d01554b82aaaab98d80000000";
        PartData[Part.Head][9] = hex"842b9ed573d3382e8282200000000a2812492cb04aa0492596c1b28124b2cb08ea000000002c2824924a40cee000000000003bc0124924965b6c44b8000000000000";
        PartData[Part.Head][10] = hex"852b736cd3a87e40ac8281600000000001fd0492e424924024b8ed2524173024a5a92483d586db6db904b60249249490b6b000000000";
        PartData[Part.Head][11] = hex"832bd7bbac483482048807080c501402851a15552b871e155546f8934555542a99e2dd000000d020d982aaabe3f60abbbf9234000000";
        PartData[Part.Head][12] = hex"842bd711d8d948ea828428000040e1b6dc06d4000000004f90492492490124924924212800000000";
        PartData[Part.Head][13] = hex"852bd7d0bb97733870b3028e0000002c482498db04e582496dc741c1a1b8db6e46c249e1b6db71b6ca0b51825b6db65b25201475d765752483fa02db6db6db5da2743b68af0a81820800";
        PartData[Part.Head][14] = hex"816c90512ea2026003e1fc729ff2aa7fcdb4000a40c200";
        PartData[Part.Head][15] = hex"832b9056ba406c8202a0200008d010000828080005f4040003ea0200026d0100017295d555d3c000000000";
        PartData[Part.Head][16] = hex"842b56819ca4386c92032000015609224124049244833a0524912421d029248921474072491b6d860f05249249124871e000000000044700";
        PartData[Part.Head][17] = hex"832bccd7a2382a93028a0002638aae10922aab86050b52f87e50b32f89c58aaafe2dd600007f82aaaa7e000000012a00";
        PartData[Part.Head][18] = hex"824b2bcc403092043000030e000050c00018881cb0000842091000002cc00000d14b54aabcd2d52ab11c00000004cf00000000";
        PartData[Part.Head][19] = hex"842b81d856d949329204500000a384925023a000000002f1019f824924b6d864459000000028986c632000";
        PartData[Part.Head][20] = hex"84123d2bd8d950a87202100388030c1208982416b0492092414a48a56057aa4524e5d36db880";
        PartData[Part.Head][21] = hex"842bd711ac10406c828250000000008301249249641ee824924924b20124924b2cb0f580924965b626a824924a41714092492d8d6a0000000000";
        PartData[Part.Head][22] = hex"822bc7d640ec820460000940aaa886055545f4555543dc15555525f000000000";
        PartData[Part.Head][23] = hex"882b1868123d318e3743406c820540000026c0a686608600d05c4cc17d01a23a19a983ea043533453309980444cc45111016b804c4cd0ccd14cc356000000000000000";
        PartData[Part.Head][24] = hex"822bcca2402e920388050809880b30a2845628aca863a2acb2c881a2cacac8a1c2b2cab23078b2acb2a38f0a28b2b1040428844302b1346080";
        PartData[Part.Head][25] = hex"832bd5d3a938aaa201080410020420ab05403f820555416e8d3555c1e715555d7899a55d77f8b826bf200078e8270800";
        PartData[Part.Head][26] = hex"812b7950a883031003467c5c87f21adff3fe7fc000";
        PartData[Part.Head][27] = hex"822bba72287282832000001a50aaaa85ea1555510002228555545200a821165455554335c4140aaaa8051fe42aaaaaaaa4ac0000000000";
        PartData[Part.Head][28] = hex"822b5580406c828520004900aa82050d5528bd4355523e500000131835554a5ae8d5554a8000000000";
        PartData[Part.Head][29] = hex"822bc79d50a883811000000b822aaac0aaab02aaac0aaab02aaac0000000";
        PartData[Part.Head][30] = hex"832b3b6534406ed2830c0050e0d20469169543258acaaa20b4569557145a2d2aaf8c1f15a557fc000003fc8b21f93633cab19e5d88ccc000";
        PartData[Part.Head][31] = hex"822bc19650ae83012000001c50aaab070a1555615142aaac38a455558005555aa000000000";

        PartData[Part.Eye][0] = hex"802b62dec081ce00";
        PartData[Part.Eye][1] = hex"81d92b62e0c1021e50c0";
        PartData[Part.Eye][2] = hex"802b52e2b1085800";
        PartData[Part.Eye][3] = hex"802b631ec08600";
        PartData[Part.Eye][4] = hex"81d92b62dec081de80";
        PartData[Part.Eye][5] = hex"81562b5aa2c108101e0b83ccc8";
        PartData[Part.Eye][6] = hex"81562b62e2c102246880";
        PartData[Part.Eye][7] = hex"822bd9d65aa2c181024a0b4bad2d24b0";
        PartData[Part.Eye][8] = hex"802b5ae0c080a39400";
        PartData[Part.Eye][9] = hex"81562b5ae2c10412107080";
        PartData[Part.Eye][10] = hex"812bd662e0b08ae8";
        PartData[Part.Eye][11] = hex"802b629ec08071e580";
        PartData[Part.Eye][12] = hex"812bd962e0c1029ef0e0";
        PartData[Part.Eye][13] = hex"81d92b62a0c1021e51c6a0";
        PartData[Part.Eye][14] = hex"81562b5a9eb08438cca0";
        PartData[Part.Eye][15] = hex"812bd962a0c1029eb1beb8";
        PartData[Part.Eye][16] = hex"81d92b62a0c1021e31aea8";
        PartData[Part.Eye][17] = hex"812bd75260c2000620c414a500";
        PartData[Part.Eye][18] = hex"802b52a8c20420a2174001811b10";
        PartData[Part.Eye][19] = hex"812bac4268d281100e20348e26471a8a8a1cb48e6a20ec40";
        PartData[Part.Eye][20] = hex"812bd7526cc2014000cc0003564413d000cc00";
        PartData[Part.Eye][21] = hex"812b424aaac281000032636648080600";
        PartData[Part.Eye][22] = hex"822b5690422ac3012000001d30aaaa800d554800aaaa8e48000000";
        PartData[Part.Eye][23] = hex"812b814a6ac282700372ff06d8507000";
        PartData[Part.Eye][24] = hex"832b8257ac422ac30028000001d00beaf8012a4a80150c042a1c8403f080";
        PartData[Part.Eye][25] = hex"812bb24a68c20220c219ec60ce9b4a254200";
        PartData[Part.Eye][26] = hex"822bb43552a6c20200000568a0500064c000";
        PartData[Part.Eye][27] = hex"814fd75a9eb1021e30a0";
        PartData[Part.Eye][28] = hex"81822b5aa2b1820942b480";
        PartData[Part.Eye][29] = hex"802b5aa0c10107068800";
        PartData[Part.Eye][30] = hex"81812b629ec08071eda0";
        PartData[Part.Eye][31] = hex"802b5aa4b1022c2860";

        PartData[Part.Tail][0] = hex"812bd9b5f19100366800";
        PartData[Part.Tail][1] = hex"822bd9d8b53992062038049941da8440c10ea8d04a6000";
        PartData[Part.Tail][2] = hex"822bd7bab2bb610540663053283a82405a0d01d8440961482c8600";
        PartData[Part.Tail][3] = hex"822b3c68b43b7186802a0c88e15519c2aa45054ad01803407280";
        PartData[Part.Tail][4] = hex"822bd8d7b2f7820120032150310a02462860c50f98a263145a4233211c908fa05014906a938800";
        PartData[Part.Tail][5] = hex"812bd8b3796182404b622d8c363d1c95b2b8e631ce1e3f20";
        PartData[Part.Tail][6] = hex"812bd8b3bb7184405c712a119ce90e54a73e6508e29d02724200";
        PartData[Part.Tail][7] = hex"812bd8b33b81850189146c7524a92c6cd1276da136910d41f5853000";
        PartData[Part.Tail][8] = hex"812bd8b57591800a652cf7d480";
        PartData[Part.Tail][9] = hex"822bd8d9b47b8286200a213089895866a2a412942a918156038100";
        PartData[Part.Tail][10] = hex"822bd8d9b439818680261307d2585a0a8ec1623a4b15456316d1c200";
        PartData[Part.Tail][11] = hex"822bd8d9b4f5720840d8282c285040";
        PartData[Part.Tail][12] = hex"822b8910b3f9618680260d0842a1840400981590c400";
        PartData[Part.Tail][13] = hex"822bd8d9b5338204409c30b0d000";
        PartData[Part.Tail][14] = hex"822bcdd4ca7ba182006400b4c904c954c9a4c9f402502a02f03403903e043047404c405140558000";
        PartData[Part.Tail][15] = hex"822bccd7b1fb6183400a82a11c2aa19c35221c2ca2a832328323b4043404c05405b06306a072078200";

        PartData[Part.ColorContainer][0] = hex"842bdadbdcdd1d4db2842012e0000901201b02400000";
        PartData[Part.ColorContainer][1] = hex"842bdadbdcdd048fb28218000b0804800a8019003c0083e0924901249201b6db024924104a24904a180000";
        PartData[Part.ColorContainer][2] = hex"842bdcdddadb0c51b2031005180013100d003a011004a014a86db0c54492071e0924901249212542490a460000";
        PartData[Part.ColorContainer][3] = hex"842bdadbdcdd044fb2830802800680112800006400f0022004a00a40170030f82492404924806db6c092490512800000";
        PartData[Part.ColorContainer][4] = hex"842bdadbdcdd0d4fb28210040803d012090124900db6c3a412412884168000";
        PartData[Part.ColorContainer][5] = hex"842bdbdcdadd0d11b206201460b08a825b0c7824b6c04949052a1290646141d880";
        PartData[Part.ColorContainer][6] = hex"842bdbdcdadd0d4fb1050008412d60e81296d80de0250520910a760b2000";
        PartData[Part.ColorContainer][7] = hex"842bdcdddadb0351b282018a81900197900001c801d80210022002500270029802b802d9836db0c8612490364412492404924907f3000000";
        PartData[Part.ColorContainer][8] = hex"842bdadcdbdd04cfb181a000008e092db046825b06982c23202a6140c684a40e384949041a000000";
        PartData[Part.ColorContainer][9] = hex"842bdadcdbdd0d8db28230001ae096c025b0129004a40f8c0000";
        PartData[Part.ColorContainer][10] = hex"842bdbdcdadd0d4fb28420010405b075012db00912009290484094160800";

        SkinData[0] = [179,136];
        SkinData[1] = [215,172];
        SkinData[2] = [214,171];
        SkinData[3] = [210,168];
        SkinData[4] = [207,164];
        SkinData[5] = [204,162];
        SkinData[6] = [198,157];
        SkinData[7] = [172,129];
        SkinData[8] = [171,128];
        SkinData[9] = [177,134];
        SkinData[10] = [173,130];
        SkinData[11] = [137,94];
        SkinData[12] = [136,93];
        SkinData[13] = [209,166];
        SkinData[14] = [203,160];
        SkinData[15] = [196,153];
        SkinData[16] = [65,22];
        SkinData[17] = [135,92];
        SkinData[18] = [178,135];
        SkinData[19] = [208,165];

	}

	
	
	function getImageCompressData(uint8[4] memory _colorList, spriteBody memory _sp) view internal returns( bytes memory imageBytes) {
        uint8[2] memory skin;
        bytes[7] memory imageData;
       
        skin = SkinData[_sp.skinColorIndex];
        
        imageBytes = abi.encodePacked(_colorList[0],_colorList[1],_colorList[2],_colorList[3],skin[0],skin[1]);
        
		imageData[0] = PartFaceData;
        imageData[1] = PartData[Part.Trunk][_sp.trunkIndex];
		imageData[2] = PartData[Part.Mouth][_sp.mouthIndex];
        imageData[3] = PartData[Part.Head][_sp.headIndex];
		imageData[4] = PartData[Part.Eye][_sp.eyeIndex];
		imageData[5] = PartData[Part.Tail][_sp.tailIndex];
		imageData[6] = PartData[Part.ColorContainer][_sp.colorContainerIndex];
		
		for(uint i=0;i<7;i++){
		    uint32 imageLen = uint32(imageData[i].length);
		    imageBytes = abi.encodePacked(imageBytes,imageLen,imageData[i]);
		}
	}
}

 