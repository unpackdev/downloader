// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./console.sol";

import "./ERC721.sol";
import "./IERC2981.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract AuroraGuardians is ERC721, IERC2981, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Aurora Guardians", "AGT") {
        for (uint256 i = 0; i < 150; i++) {
            _mint(owner(), totalSupply());
            supplyCounter.increment();
        }

        apollXMemberMap[0x3e390b35700BbbB9a36024f554F8b89c354175a1] = true;
        apollXMemberMap[0xD2dE99Aec586d966EEC7E98EEB73F49840A6186D] = true;
        apollXMemberMap[0x4766c60dee2852d7bB351dcE9bBDCdb55643dE4e] = true;
        apollXMemberMap[0x2A1701e979ec7c2209964aCbf4686dAAa68e9929] = true;
        apollXMemberMap[0x9E323318EfC2682FC47eA7cAB63F1d924B5EC12A] = true;
        apollXMemberMap[0x640149C30ba94C14eF7C1dC354c4a73258f64F03] = true;
        apollXMemberMap[0x4E8Ada817B9d0469191f2aB00722e189Cd0cf717] = true;
        apollXMemberMap[0x56BdF4b2f8D854aE62b151C52dc9915036d4c7fc] = true;
        apollXMemberMap[0x640149C30ba94C14eF7C1dC354c4a73258f64F03] = true;
        apollXMemberMap[0x640149C30ba94C14eF7C1dC354c4a73258f64F03] = true;
        apollXMemberMap[0x311675b42cd3e737203Dd77AC38AAAdd0a2F72D1] = true;
        apollXMemberMap[0x32417DC69162e493CAE4648E6919e468b28a2F56] = true;
        apollXMemberMap[0x27F280fE58b72bD100B281767f93957d9E2Fed09] = true;
        apollXMemberMap[0x3a7C2B99D8a3A8064650025a5Eb5cFB44C19814e] = true;
        apollXMemberMap[0x40d4b664317E57dBAa71d261A576d9bcd4a4f602] = true;
        apollXMemberMap[0x81c40f46afd9b140054bC038891B36cf74EAEFC9] = true;
        apollXMemberMap[0x334D3ef76B1192D704A5eb78e7F2C9A7b002aAC2] = true;
        apollXMemberMap[0x6DA33A00B82249fCaEA75F036Ee957E6D6B179E2] = true;
        apollXMemberMap[0xC6c5eE2C54c79695EbEf26f3171e5b96Ed74578d] = true;
        apollXMemberMap[0x072DF329e2B6853D47964527c442668483F5c648] = true;
        apollXMemberMap[0x3747Df5378b7A681e54dCC4C7A52aB7BA174b770] = true;
        apollXMemberMap[0xebE7E229783dC3fadfa4dD8b2e3C42e5E9180337] = true;
        apollXMemberMap[0x339858A776bb65f4f4F12D5aB8aA40EB3447cB2e] = true;
        apollXMemberMap[0x0DF3A0301387F44d2888D73CFf27DfF99139D28E] = true;
        apollXMemberMap[0xE00F5F98CE064484c30E45002618c46F31272Bdc] = true;
        apollXMemberMap[0x23E31129bfA2d2E4bda3d3C0c20695b7E666e329] = true;
        apollXMemberMap[0x56B6673c3bc30Fbd588EA60BD32228AC1947387D] = true;
        apollXMemberMap[0xb92EC1a4ef46A04b4060adCd806ad05dee9d4025] = true;
        apollXMemberMap[0x40d4b664317E57dBAa71d261A576d9bcd4a4f602] = true;
        apollXMemberMap[0x9aE3856857265B99764934023bb0e29d3f46EAe8] = true;
        apollXMemberMap[0xC8fC8ab4935e988C359CD9435B3529794a785398] = true;
        apollXMemberMap[0x23E31129bfA2d2E4bda3d3C0c20695b7E666e329] = true;
        apollXMemberMap[0x017A9F36Cb998cD0A542592943feceb177679a35] = true;
        apollXMemberMap[0x54eC468c92B4b765FA7Ef4fd9E96E2a06F6d1251] = true;
        apollXMemberMap[0x3a7C2B99D8a3A8064650025a5Eb5cFB44C19814e] = true;
        apollXMemberMap[0x3Ae36C5b80b2b22151e31AD8aDB666AB3605bf65] = true;
        apollXMemberMap[0xa894077e96375BdBdA09d93627bbe7E4Ca52fAd1] = true;
        apollXMemberMap[0x5B33ea8B7836FF4D14C75F0d461Fc67a23D777F0] = true;
        apollXMemberMap[0xfF7528c341E2374C68EB37272DBA892Ff5D2F91D] = true;
        apollXMemberMap[0xaa32D46F962C547A4dEb586404884203b06C1AB9] = true;
        apollXMemberMap[0x4cE95d32Af9Fd7529BB8F222988B369c8897a087] = true;
        apollXMemberMap[0xe69a97433B9cDFd3623fC5176E05B2B0ED702130] = true;
        apollXMemberMap[0x896D643910Ed405E3F6Bb2fA6290064344353B55] = true;
        apollXMemberMap[0x0A966D3a3c94D2F26d40B4419E4916e815b87098] = true;
        apollXMemberMap[0x6fF6051256329023BAfBcAdf73596be5d1e09B76] = true;
        apollXMemberMap[0x311675b42cd3e737203Dd77AC38AAAdd0a2F72D1] = true;
        apollXMemberMap[0xb661df6c7d0A4db3716DaAC9833F5dee20d0B400] = true;
        apollXMemberMap[0x4079e80D6193D20bB807cA38aB929a40eb8Bdddf] = true;
        apollXMemberMap[0xB51367929e153CadC8856695C165CeA08324C349] = true;
        apollXMemberMap[0xD9498e2fc646B5882e78a6243FB5EfAeDc1cD85f] = true;
        apollXMemberMap[0x756709C4F18bCf876CDBEA342aD9F755A0244D0D] = true;
        apollXMemberMap[0x630926986260A11cfa8d4EF7B4aeE03d5D07731A] = true;
        apollXMemberMap[0xE2433bE04016637253fCb13409B90ffe12F6633A] = true;
        apollXMemberMap[0xF24386BC867b3DA017cA0816B8979dba4dbABC6A] = true;
        apollXMemberMap[0x64F6A225858FA1aa14790171B2E82cf3b6Df09F3] = true;
        apollXMemberMap[0x9fcd43b3899CE7836366Dc41a72e7003DA2D895c] = true;
        apollXMemberMap[0xcd71A3972F7A21DD4eF9FEbac48Bf96cE727E066] = true;
        apollXMemberMap[0xE63e5Ea3a32478434de79CBD0822A55CF6833274] = true;
        apollXMemberMap[0x82DF2568b5b7E5E48f036B90444980F77410986A] = true;
        apollXMemberMap[0xe030DB708fEDA9aAc779C56974A6C74ECfb95A27] = true;
        apollXMemberMap[0x33D3f517543124455196AF2BB498A40B4AD5078f] = true;
        apollXMemberMap[0xB9731875AFB73D926eF9D968F7bd4b92A5B590a9] = true;
        apollXMemberMap[0xebE7E229783dC3fadfa4dD8b2e3C42e5E9180337] = true;
        apollXMemberMap[0xD07C360Dee6c1D977Ae9EC628197Cf8ed1031E2E] = true;
        apollXMemberMap[0xbAB5144Fb9661aA52487548c92d7bE56d47EEdD8] = true;
        apollXMemberMap[0x69023DddaB45f345f2B683c180001d017FC0a540] = true;
        apollXMemberMap[0xa1d2aB323EAF3b1F79E4392A307bC8aeE2ffe4A8] = true;
        apollXMemberMap[0xda32350E688063A07b58e716F3D7Ee7e76674db9] = true;
        apollXMemberMap[0xC8fC8ab4935e988C359CD9435B3529794a785398] = true;
        apollXMemberMap[0xEFA34AFA85636fFf9e5aCE31C890c859D728e260] = true;
        apollXMemberMap[0x606F68667F9F2f1E1F7401D5e423fd62AC5B4622] = true;
        apollXMemberMap[0x9fcd43b3899CE7836366Dc41a72e7003DA2D895c] = true;
        apollXMemberMap[0x653919E4e8D55B98B03715b2Dc66357683d015ad] = true;
        apollXMemberMap[0xBa6E38219Ac69Cd42E2b40EAe1f91c7bd0762449] = true;
        apollXMemberMap[0x59975dFE25845bF9C0eFf1102Ac650599c3f491a] = true;
        apollXMemberMap[0x9b09c4412D656E628317F558545c031680903901] = true;
        apollXMemberMap[0x2F72672C36e616b4CAB7a95a9dfB2dFa17ab9bb6] = true;
        apollXMemberMap[0xFBbDaad576021E2a4433bccC530C65639aBDB734] = true;
        apollXMemberMap[0xa8ad3C8D9039a0D10040d187C44336e57456fecE] = true;
        apollXMemberMap[0x0C1138cf05e3c17f5643DceFFC3f86d99C98e5a5] = true;
        apollXMemberMap[0x0057B37A2aE4eF70162acD35ef2DE2D7c537a200] = true;
        apollXMemberMap[0xa81824002C1DbfCD20DBdA9B8003b398097E4FF1] = true;
        apollXMemberMap[0x0fccd63c11bDB7155aa8De1262F273140C91007d] = true;
        apollXMemberMap[0x1A2Be848d7958570966cC20b1C521d8945cDA8C1] = true;
        apollXMemberMap[0xBa6E38219Ac69Cd42E2b40EAe1f91c7bd0762449] = true;
        apollXMemberMap[0x0B8e20C2aE1E4A6Ba243b2dA113625128f31D858] = true;
        apollXMemberMap[0x5395e4c9131bfDF347A3D2dcA1D4702Db525Af24] = true;
        apollXMemberMap[0xa16D88ca43c6FE5D5e6FaC3cb5E54BD6b39443e8] = true;
        apollXMemberMap[0xA19bba98145dE26643e572403fcB929037D58741] = true;
        apollXMemberMap[0x640149C30ba94C14eF7C1dC354c4a73258f64F03] = true;
        apollXMemberMap[0x0B8e20C2aE1E4A6Ba243b2dA113625128f31D858] = true;
        apollXMemberMap[0x6D08aA70e3A043D8c518d27e7f178ae37fbDF9Bc] = true;
        apollXMemberMap[0xa16D88ca43c6FE5D5e6FaC3cb5E54BD6b39443e8] = true;
        apollXMemberMap[0x320dFBF15FdD732580C6815cBAeB4A136926814F] = true;
        apollXMemberMap[0xc7230D095b012A4E5EA9A4A98961Fd90c369857a] = true;
        apollXMemberMap[0xa16D88ca43c6FE5D5e6FaC3cb5E54BD6b39443e8] = true;
        apollXMemberMap[0x506cBF086BB66c985CfcA2bEF212A1d6847b50d5] = true;
        apollXMemberMap[0x17A77D63765963d0Cb9deC12Fa8F62E68Fee8fD4] = true;
        apollXMemberMap[0xC04D3B4aDffd4B6c7413F59E7825FF289E639D48] = true;
        apollXMemberMap[0xeb311c71459d04fa75f0Be04015B7DCb46bfD9DB] = true;
        apollXMemberMap[0xdb18A06d2A8Aef995F7A50B61D5499d16aF060f8] = true;
        apollXMemberMap[0x3024859843Be03bDb52b169b74C4636d85Eb0870] = true;
        apollXMemberMap[0xaaa83E135399634Ef57EFF2174bf927419C1EFc3] = true;
        apollXMemberMap[0x6a9C60Cd0051E200F6E6DEA6666d204f5f6c1bAb] = true;
        apollXMemberMap[0x90cEDCfa35C9314C57bfA66139e1285DA276080F] = true;
        apollXMemberMap[0x15B883DA52396A4322E8f5E7a638EB37656Afe63] = true;
        apollXMemberMap[0x9b09c4412D656E628317F558545c031680903901] = true;
        apollXMemberMap[0xd81f61861301C7714853d0DE9419896f48D1293C] = true;
        apollXMemberMap[0x31b85DB063D4898A283a192734A13B146D7C6f1b] = true;
        apollXMemberMap[0x24D5EfB2C9C40Bc7732524B528643eab704bf9d3] = true;
        apollXMemberMap[0x55D976173f08c010F22fE1c4EA1658310B010264] = true;
        apollXMemberMap[0x862f3C4650591be3B7ae8250C392C4E1C7C692E6] = true;
        apollXMemberMap[0x58aF80587cc80984265c04DfDb905EB38fe2Cbe0] = true;
        apollXMemberMap[0x5111dA863fB9828c83B356E5e61Ab79e0BFB7b60] = true;
        apollXMemberMap[0x19948cf35a09CC6C7878167152f69ad1BeD5190b] = true;
        apollXMemberMap[0x23E31129bfA2d2E4bda3d3C0c20695b7E666e329] = true;
        apollXMemberMap[0x59975dFE25845bF9C0eFf1102Ac650599c3f491a] = true;
        apollXMemberMap[0x017A9F36Cb998cD0A542592943feceb177679a35] = true;
        apollXMemberMap[0x5aD1a78D7D102f2AB24998323363461e3219A60d] = true;
        apollXMemberMap[0x4eC3B52C788f58a6f273F33e4cbC38ae2cBfE6C8] = true;
        apollXMemberMap[0x344E75d3C70A43333227Da69f78e9953F4B8B227] = true;
        apollXMemberMap[0x62f3215e3b823c5d3fD8d791D270625eF617538E] = true;
        apollXMemberMap[0x6a9C60Cd0051E200F6E6DEA6666d204f5f6c1bAb] = true;
        apollXMemberMap[0x78C269eE1F90F93500ddEf91b97d6be2F0bF2d14] = true;
        apollXMemberMap[0xd2170cb266bb1be2a2680C85775E51343cD4984F] = true;
        apollXMemberMap[0x9c98C7bCd1c93B5F315D7C213455B89634CE8183] = true;
        apollXMemberMap[0x093F7075F0ef4A660B069D581A6DfECAaeDfe229] = true;
        apollXMemberMap[0xEbf22200607acb1433ebcb53f71b061d387BDc26] = true;
        apollXMemberMap[0x63Ee5AD70D6DB3bd4B4cd77055370B20CC2BcE31] = true;
        apollXMemberMap[0x9A8c656FD330C23Bec624db0Cf98e6A2a086FA0c] = true;
        apollXMemberMap[0x862f3C4650591be3B7ae8250C392C4E1C7C692E6] = true;
        apollXMemberMap[0x23a35Eb32b713BB1370069A5d440Ae6d3aB378D9] = true;
        apollXMemberMap[0x502eF5BC55B6483B40Df5fe81C8B27a03f3c0658] = true;
        apollXMemberMap[0x9aa61a5084fEA26238aed17D37eef4cbe8014320] = true;
        apollXMemberMap[0x488CB7D6F7596ACcf0544913Aa9e0d0f38F315F4] = true;
        apollXMemberMap[0x599dbB08816FF0581569d50d7c3C616E33dde697] = true;
        apollXMemberMap[0xa9832f25a686483dffEb43f58D61aa9E0F20024a] = true;
        apollXMemberMap[0x1da4eE7c7086a9204cF091E28738DA68B7E52942] = true;
        apollXMemberMap[0x5e835798876124f5bdeA5682a37F15100EE58903] = true;
        apollXMemberMap[0x3a7C2B99D8a3A8064650025a5Eb5cFB44C19814e] = true;
        apollXMemberMap[0x32417DC69162e493CAE4648E6919e468b28a2F56] = true;
        apollXMemberMap[0x315BD7cA72934502B4a4683D7F6ba9fad1362473] = true;
        apollXMemberMap[0x2c1d45567D7526b551e46c26a0982AF04b709106] = true;
        apollXMemberMap[0x5111dA863fB9828c83B356E5e61Ab79e0BFB7b60] = true;
        apollXMemberMap[0x70820CF50D380cC83b571fBd872ABA61bDaE6c44] = true;
        apollXMemberMap[0x56B6673c3bc30Fbd588EA60BD32228AC1947387D] = true;
        apollXMemberMap[0x9E323318EfC2682FC47eA7cAB63F1d924B5EC12A] = true;
        apollXMemberMap[0x021804BC0F94aE40F489eA9cEF26019354479a12] = true;
        apollXMemberMap[0x58aF80587cc80984265c04DfDb905EB38fe2Cbe0] = true;
        apollXMemberMap[0x58F6102d32ea03811EB7075C90C82e58c0c4Cf34] = true;
        apollXMemberMap[0x505F8439C86FDc49058a601F6d64D5f76585BC1d] = true;
        apollXMemberMap[0x62E1Ab51A839c87dBB6e124c51E714118199CD7E] = true;
        apollXMemberMap[0xd093f8b4D8b9fB2847a49460e7b7a39340b2f07b] = true;
        apollXMemberMap[0xb92EC1a4ef46A04b4060adCd806ad05dee9d4025] = true;
        apollXMemberMap[0x7bbb4521542677c0D5E777Aa97baD2df75f87c97] = true;
        apollXMemberMap[0x36dd82428DaB08505142b5989481D3ccF589b54C] = true;
        apollXMemberMap[0x6dd0b33745f4a43CE331DAa315FA308c1fFD1048] = true;
        apollXMemberMap[0xEeE1b7B4Ae1516D68d8C154efD803B4601A59Be4] = true;
        apollXMemberMap[0x5B25adE8DbA55fe6D3D7F7719018504899B729e2] = true;
        apollXMemberMap[0xfF0c68CdC0Dd46A6eD8ba68e887A2a673C46F4E6] = true;
        apollXMemberMap[0xbE5BF161662f321bC356e646C22dD571d9F7c909] = true;
        apollXMemberMap[0x6efa7b45769842f83C926F4403d8a8417596E90B] = true;
        apollXMemberMap[0x02736d5c8dcea65539993d143A3DE90ceBcA9c3c] = true;
        apollXMemberMap[0x49f5A86FAC6761f7Ed534dbCe069c9ac6f9f9574] = true;
        apollXMemberMap[0xebE7E229783dC3fadfa4dD8b2e3C42e5E9180337] = true;
        apollXMemberMap[0x1A2Be848d7958570966cC20b1C521d8945cDA8C1] = true;
        apollXMemberMap[0x11bEDd46173691AD986a6e40c3e278664B039aa4] = true;
        apollXMemberMap[0xB2717D2c76B1Ecb713eC1fF352e9d9F354C9a9B1] = true;
        apollXMemberMap[0x1D2eD6e3E540E34752488f577bEC3C65117fC10F] = true;
        apollXMemberMap[0x102E58e9A907cBd09a6C8A78AfE7ECebeC69D16f] = true;
        apollXMemberMap[0xc8F84657e587B4acc6C2D6bFb03fd35AAEeA26fa] = true;
        apollXMemberMap[0x504064820346bfc5aC5143781103Fa8AA0Bb3FB4] = true;
        apollXMemberMap[0x32417DC69162e493CAE4648E6919e468b28a2F56] = true;
        apollXMemberMap[0xCec3D6d9eAC5469cb31730EE3f5556843282807e] = true;
        apollXMemberMap[0x9fd0A9f3cFd821C63b1581068e6e7D554feAE9EC] = true;
        apollXMemberMap[0x00D7d5367Bd7e3D1ba664f18ed85DC7bfB585D81] = true;
        apollXMemberMap[0x7f716B609cc9A9AE0173D0FEBc0fbaA49bE85fCC] = true;
        apollXMemberMap[0x2A1701e979ec7c2209964aCbf4686dAAa68e9929] = true;
        apollXMemberMap[0xae1BE2B708AcCBEf874781AddEf52c8633Bfc1CC] = true;
        apollXMemberMap[0x505F8439C86FDc49058a601F6d64D5f76585BC1d] = true;
        apollXMemberMap[0x62E1Ab51A839c87dBB6e124c51E714118199CD7E] = true;
        apollXMemberMap[0xd56995A017969BFc4c934dDcA9Fa9fbf6E5b1eC2] = true;
        apollXMemberMap[0x4eC3B52C788f58a6f273F33e4cbC38ae2cBfE6C8] = true;
        apollXMemberMap[0x5aD1AeE54c4DD5E7967A5B6c0014C11f95f5D7fc] = true;
        apollXMemberMap[0x98dFe9a86e6a80D914C2D246980d70A221fe0f1E] = true;
        apollXMemberMap[0x23E31129bfA2d2E4bda3d3C0c20695b7E666e329] = true;
        apollXMemberMap[0x306de2e49B06BA91e36c50F6e73f57A1BD02a746] = true;
        apollXMemberMap[0x98697CD87E42540F545ec445e864cc788369B097] = true;
        apollXMemberMap[0x285d75F141a9A7A283849dF381697029cC6F37c9] = true;
        apollXMemberMap[0x2A1701e979ec7c2209964aCbf4686dAAa68e9929] = true;
        apollXMemberMap[0x2a654A3508513E4a3890d75E47962821F2B7D09d] = true;
        apollXMemberMap[0x40d4b664317E57dBAa71d261A576d9bcd4a4f602] = true;
        apollXMemberMap[0x4E8Ada817B9d0469191f2aB00722e189Cd0cf717] = true;
        apollXMemberMap[0x51DC203b441608b7eB99c35f076C05e1A0aD3931] = true;
        apollXMemberMap[0x5e757456b2b6A66B6facF9d285fBD28a8b9a0530] = true;
        apollXMemberMap[0x72BB8b8fC002d9F09dF9C5ccE23E932262BAEb05] = true;
        apollXMemberMap[0x83F7fB78d50250619EEf4b1c4B082c21fa68D9D3] = true;
        apollXMemberMap[0xc7230D095b012A4E5EA9A4A98961Fd90c369857a] = true;
        apollXMemberMap[0xc7A6968B09CC80a48B7faE3DF0ffc959eeD9Ff2d] = true;
        apollXMemberMap[0xD436e550282161DC6ADD1dd266049eb4C13FC685] = true;
        apollXMemberMap[0xe5dcB8d2DeeBBD756A401ad3daDd8d5c7Ce6d081] = true;
        apollXMemberMap[0xd20a0f3fa1Edbc6f2d948BC90F73B7529082265b] = true;
        apollXMemberMap[0xbf872C334Db9b24da877c134D57f63F24D3B2A06] = true;
        apollXMemberMap[0x2C55c770Dc6b8C2Df7477e42A697bd44cF777373] = true;
        apollXMemberMap[0xf7C9CaE52b345f3C8dc8105577E87f7911B52f4D] = true;
        apollXMemberMap[0x205BBBE1b5EE65efFe19c5DD59b84AD1413BBB77] = true;

        allowListMap[0x51E1886Cd4BECc1Fc9878D4f58F7BAcB05ce7D2E] = true;
        allowListMap[0x02c523A8a66dfdc5F01BE54f269d9da601c1229A] = true;
        allowListMap[0x01512D5e3370b4b5C98649a6067331eCeFa8711A] = true;
        allowListMap[0x22D02786f813A70c5699621810D0ea85efA07332] = true;
        allowListMap[0x091f3B40936d0df412e0606892E34a324aE86F83] = true;
        allowListMap[0x2AC2d0164Ad8E3cAf0E47487F371ed94ec7ee1a7] = true;
        allowListMap[0x6CFab518eeD2486bdc5e8605471c7b1999157363] = true;
        allowListMap[0x47Ab1940F66E91948cA41f1D22a70fBC984a6591] = true;
        allowListMap[0xfF7528c341E2374C68EB37272DBA892Ff5D2F91D] = true;
        allowListMap[0x4287De1fA45D3b94B39eafBf17259daFfC69E6a1] = true;
        allowListMap[0xC2F14b7be2d39161718B14E07CA2a5c0A0C9a14E] = true;
        allowListMap[0xaFdb99DEF38a49D24A5189D341fC96F4729f27D6] = true;
        allowListMap[0x448225498e0C3A64eCd0820c5f2400d3462EFB74] = true;
        allowListMap[0xa2caf890b285552Bd946b07B95b96ae6025f92ac] = true;
        allowListMap[0xc7A6968B09CC80a48B7faE3DF0ffc959eeD9Ff2d] = true;
        allowListMap[0xB196C4f3389DA246Ac569C78D7538525b5382918] = true;
        allowListMap[0xa16D88ca43c6FE5D5e6FaC3cb5E54BD6b39443e8] = true;
        allowListMap[0x2A1701e979ec7c2209964aCbf4686dAAa68e9929] = true;
        allowListMap[0x5B860f1A47c1208924Ce530D0A076B8231C6bDBd] = true;
        allowListMap[0xC8fC8ab4935e988C359CD9435B3529794a785398] = true;
        allowListMap[0xa8ad3C8D9039a0D10040d187C44336e57456fecE] = true;
        allowListMap[0x889d5ff009191afD466D8B8b395646b9F807A7e6] = true;
        allowListMap[0xd81f61861301C7714853d0DE9419896f48D1293C] = true;
        allowListMap[0xBd1C357Fe5d7383bF919Ffb5Fc83ee5006c941A0] = true;
        allowListMap[0xe62338030c81265BB1C16d939F36561E591B9c88] = true;
        allowListMap[0x205BBBE1b5EE65efFe19c5DD59b84AD1413BBB77] = true;
        allowListMap[0xbBfffC6a679F2BA050217a6a5EEEFD9EaFd64930] = true;
        allowListMap[0x4db0e8679e556adaefF492219e17adAEB3c547d4] = true;
        allowListMap[0xE2433bE04016637253fCb13409B90ffe12F6633A] = true;
        allowListMap[0xEBE326d8De3413F8132518dcFd45e6cBFf7E5c27] = true;
        allowListMap[0x48c4a95447332CD5b96bF3e069Bd3f3D74aC8119] = true;
        allowListMap[0x137A7977365DdfDFFe0D3eC2562521E7b79f5769] = true;
        allowListMap[0xBfcC73DC4b03f0fEBb5Ce1d53e5E410a3ee8CFC1] = true;
        allowListMap[0xAE7bb0aEb81cFB59ab96BCb0C29500eC8174f71c] = true;
        allowListMap[0x1A2Be848d7958570966cC20b1C521d8945cDA8C1] = true;
        allowListMap[0xF35fd92A51e1906B3B6E5214B341Da51685341dB] = true;
        allowListMap[0x02736d5c8dcea65539993d143A3DE90ceBcA9c3c] = true;
        allowListMap[0x59975dFE25845bF9C0eFf1102Ac650599c3f491a] = true;
        allowListMap[0xC7c2C3b5B5ecABA2C26553f424A31940Cf1B9BeA] = true;
        allowListMap[0xE37582Cb7ae307196D6e789b7F8CCB665D34ac77] = true;
        allowListMap[0xc482a5E3b211c8e8de837A2e9d2e044e0647ADE8] = true;
        allowListMap[0x4f59722b18DE4D618f8285AacE57A7197817BC3d] = true;
        allowListMap[0x2BA307C0159B44B2ea09935Ddf901Bab174131B0] = true;
        allowListMap[0x0371aC9EF21c4502c7D17bd2d06cCdf1eC734e5F] = true;
        allowListMap[0x41aCEbb90012ce53aFBA770b032eB910F5C0Ff3F] = true;
        allowListMap[0x4858E4AB1B2E9583bfc60B1FFA3251C3d4e5ceA9] = true;
        allowListMap[0x83F7fB78d50250619EEf4b1c4B082c21fa68D9D3] = true;
        allowListMap[0xF5E5Cb693CD31b7D8d40B56e12a359558Bcab91F] = true;
        allowListMap[0xD99836319A334E919730345660cD2715aAC487e1] = true;
        allowListMap[0x53CcCcF81412fACa6Bb4eAc5E7885EC754485aa1] = true;
        allowListMap[0x70E0861Ffc6Ee887f8e168F35CF842C933449103] = true;
        allowListMap[0x2FeA24CCE8998Dba01a61b34c596f1900a836880] = true;
        allowListMap[0x5DE8B02fEe94C1E8Edd3E14cE31b1e056af99bd8] = true;
        allowListMap[0xfdFe0847CD314D7c3855A6F19D83E92355Cd4E8a] = true;
        allowListMap[0xC6559765F9a9864Cd0337a853183FE838d3DfC81] = true;
    }

    Counters.Counter private supplyCounter;

    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public constant MINT_LIMIT_PER_WALLET = 5;
    uint256 public constant MINT_PRICE = 5000000000000000;
    string public customBaseURI = "https://aurora-guardians.apollx.workers.dev/";

    mapping(address => uint256) private mintCountMap;
    mapping(address => uint256) private allowedMintCountMap;

    mapping(address => bool) private apollXMemberMap;
    mapping(address => bool) private allowListMap;

    bool public saleIsActive = true;
    bool public apollxListIsActive = false;
    bool public allowListIsActive = false;
    bool public publicMintIsActive = false;

    function mint(uint256 count) public payable nonReentrant {
        require( (totalSupply() + count ) <= MAX_SUPPLY, "Exceeds max supply");
        require(saleIsActive, "sale is not active");
        require(count <= MINT_LIMIT_PER_WALLET, "you want more that you can mint");

        if(apollXMemberMap[msg.sender] && apollxListIsActive) {
            mintController(5, count, "");
        } else if(allowListMap[msg.sender] && allowListIsActive) {
            mintController(3, count, "Insufficient payment, 0.005 ETH for token 4 and 5 in your wallet");
        } else if(publicMintIsActive) {
            mintController(2, count, "Insufficient payment, 0.005 ETH for token 3, 4 and 5 in your wallet");
        } else {
            revert("public sale is not active");
        }
    }

    /* HELPER */
    function mintController(uint256 maxFreeCount, uint256 count, string memory message) private {

        if( balanceOf(msg.sender) >= maxFreeCount) {
            require(msg.value >= (MINT_PRICE * count), message);
        } else if( balanceOf(msg.sender) > 0 && (balanceOf(msg.sender) + count) > maxFreeCount ) {
            require(msg.value >= (MINT_PRICE * ((balanceOf(msg.sender) + count) - maxFreeCount)), message);
        } else if( balanceOf(msg.sender) < maxFreeCount && count > maxFreeCount ) {
            require(msg.value >= (MINT_PRICE * ( count - maxFreeCount )), message);
        }

        if (allowedMintCount(msg.sender) >= count) {
            updateMintCount(msg.sender, count);
        } else {
            revert(saleIsActive ? "Minting limit exceeded" : "Sale not active");
        }

        for (uint256 i = 0; i < count; i++) {
            _mint(msg.sender, totalSupply());
            supplyCounter.increment();
        }
    }

    function totalSupply() public view returns (uint256) {
        return supplyCounter.current();
    }

    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a >= b ? a : b;
    }

    function allowedMintCount(address minter) public view returns (uint256) {
        if (saleIsActive) {
            return (
                max(allowedMintCountMap[minter], MINT_LIMIT_PER_WALLET) -
                mintCountMap[minter]
            );
        }
        return allowedMintCountMap[minter] - mintCountMap[minter];
    }

    function updateMintCount(address minter, uint256 count) private {
        mintCountMap[minter] += count;
    }

    function addApollXMember(address member) public onlyOwner {
        require(!apollXMemberMap[member], "Already a member");
        apollXMemberMap[member] = true;
    }

    function addAllowlistMember(address member) public onlyOwner {
        require(!allowListMap[member], "Already a member");
        allowListMap[member] = true;
    }

    /* ACTIVE HANDLING */
    function setSaleIsActive(bool saleIsActive_) external onlyOwner {
        saleIsActive = saleIsActive_;
    }

    function setApollxListIsActive(bool apollxListIsActive_) external onlyOwner {
        apollxListIsActive = apollxListIsActive_;
    }

    function setAllowListIsActive(bool allowListIsActive_) external onlyOwner {
        allowListIsActive = allowListIsActive_;
    }

    function setPublicMintIsActive(bool publicMintIsActive_) external onlyOwner {
        publicMintIsActive = publicMintIsActive_;
    }

    /* URI HANDLING */
    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        customBaseURI = customBaseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    /** PAYOUT **/
    address private constant contributor1 = 0x86a57403f59da8CF15c0f0C0e953De2DE917d0C7;
    address private constant contributor2 = 0xd56995A017969BFc4c934dDcA9Fa9fbf6E5b1eC2;
    address private constant contributor3 = 0x4cD37FA9BaC56F671870939cC7860e8C6f952891;

    function withdraw() public nonReentrant onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance * 1 / 100);
        Address.sendValue(payable(contributor1), balance * 33 / 100);
        Address.sendValue(payable(contributor2), balance * 33 / 100);
        Address.sendValue(payable(contributor3), balance * 33 / 100);
  }

  /** ROYALTIES **/
  function royaltyInfo(uint256, uint256 salePrice) external view override
    returns (address receiver, uint256 royaltyAmount)
  {
    return (address(this), (salePrice * 500) / 10000);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, IERC165)
    returns (bool)
  {
    return (
      interfaceId == type(IERC2981).interfaceId ||
      super.supportsInterface(interfaceId)
    );
  }

}