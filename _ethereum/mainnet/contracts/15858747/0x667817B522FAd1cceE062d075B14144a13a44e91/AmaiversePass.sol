// SPDX-License-Identifier: MIT
//
//                                                                                                         
//                                                                                                         
//               AAA               MMMMMMMM               MMMMMMMM               AAA                 iiii  
//              A:::A              M:::::::M             M:::::::M              A:::A               i::::i 
//             A:::::A             M::::::::M           M::::::::M             A:::::A               iiii  
//            A:::::::A            M:::::::::M         M:::::::::M            A:::::::A                    
//           A:::::::::A           M::::::::::M       M::::::::::M           A:::::::::A           iiiiiii 
//          A:::::A:::::A          M:::::::::::M     M:::::::::::M          A:::::A:::::A          i:::::i 
//         A:::::A A:::::A         M:::::::M::::M   M::::M:::::::M         A:::::A A:::::A          i::::i 
//        A:::::A   A:::::A        M::::::M M::::M M::::M M::::::M        A:::::A   A:::::A         i::::i 
//       A:::::A     A:::::A       M::::::M  M::::M::::M  M::::::M       A:::::A     A:::::A        i::::i 
//      A:::::AAAAAAAAA:::::A      M::::::M   M:::::::M   M::::::M      A:::::AAAAAAAAA:::::A       i::::i 
//     A:::::::::::::::::::::A     M::::::M    M:::::M    M::::::M     A:::::::::::::::::::::A      i::::i 
//    A:::::AAAAAAAAAAAAA:::::A    M::::::M     MMMMM     M::::::M    A:::::AAAAAAAAAAAAA:::::A     i::::i 
//   A:::::A             A:::::A   M::::::M               M::::::M   A:::::A             A:::::A   i::::::i
//  A:::::A               A:::::A  M::::::M               M::::::M  A:::::A               A:::::A  i::::::i
// A:::::A                 A:::::A M::::::M               M::::::M A:::::A                 A:::::A i::::::i
//AAAAAAA                   AAAAAAAMMMMMMMM               MMMMMMMMAAAAAAA                   AAAAAAAiiiiiiii
                                                                                                         
 // @0xZoom_  


pragma solidity >=0.8.9 <0.9.0;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

// Errors


error URIQueryForNonexistentToken();


contract AmaiversePass is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;


  string public uriPrefix = 'https://data.zoomtopia.xyz/amai/amaipass/json/';
  string public uriSuffix = '.json';
  
  uint256 public cost = 0.069 ether;
  uint256 public maxSupply;
 

  bool public paused = true;
  bool public revealed = true;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _maxSupply
  ) ERC721A(_tokenName, _tokenSymbol) {
    maxSupply = _maxSupply;
    //to mint at contract deployment. Enter address and qty to mint 
    _mint(address(0x8b008593562272fD65CD63CCcD9306bF7e8f4d51), 27);
_mint(address(0x0918Bb6c7Ec474EE426BAfF2aDaD8d9b99a8450C), 59);
_mint(address(0x55A9C5180DCAFC98D99d3f3E4B248E9156B12Ac1), 11);
_mint(address(0xf10Dc48a05edF0b4A1e2beEC730b828C7298790D), 7);
_mint(address(0x5FCc3D8E93790946aA1eBFFf29E3212E014C8ef0), 5);
_mint(address(0x78f8C78a212d64CE1148355DEE3F26a6e029EbBa), 5);
_mint(address(0xf10Dc48a05edF0b4A1e2beEC730b828C7298790D), 5);
_mint(address(0x8D065b82f2B9A0B4De2C7FCd55bf5a7B608F88dA), 4);
_mint(address(0xF74f8aD40B17887B0379D87C55C063DC2861aA2F), 4);
_mint(address(0xA4dBA4a10d540a54C31534d9dCe37534e5D8CC22), 3);
_mint(address(0xC05444251077C989b15D5460490538c983277163), 3);
_mint(address(0x0064f54f2084758afA4E013B606A9fdD718Ec53c), 2);
_mint(address(0x01E08b9566566B58cc63F2EDF6e7A94C9016117e), 2);
_mint(address(0x0419c0a5d51A549fDb1eeDED70eD893b02dF89C8), 2);
_mint(address(0x06915CE2113fF639dD3e0415ddE8b1dDe17Bfa01), 2);
_mint(address(0x09Cd3208Dd33E409FD9a8b42bC8c3C0439bFC7b1), 2);
_mint(address(0x0Ad76F6fe77683CD4408F21925c1cB03cf9270C3), 2);
_mint(address(0x0C66FC6CE1103e84BA69C5205c90e09a1fcf58F9), 2);
_mint(address(0x130D88903f9926ad7c1eBA2962c8B1b64bccd821), 2);
_mint(address(0x134d645301538370406DF6d8b0803d569BaCc242), 2);
_mint(address(0x13c8eB211b873CcD16E73B3a114303424863538a), 2);
_mint(address(0x152d06cDAa573Cb48562680D8A9d383B3EeD4b5F), 2);
_mint(address(0x16ec94931C1C3C4bbC8D3A9E8778E5f303a90ef3), 2);
_mint(address(0x1781FaCf9e7098F64eB5C5bA503FBe3238115be9), 2);
_mint(address(0x1aA666D676Fde62ae9477c75e7F501f214D1849c), 2);
_mint(address(0x1b3B2d37bF022E2Dc10F959972A04e585e349dAa), 2);
_mint(address(0x1C65841EDa71e91b0dC43DD17bd5aa52b03EE364), 2);
_mint(address(0x1E9703Bb8846869FAed61A879Ac65735D3D6A4f2), 2);
_mint(address(0x1f9573a3ABd613ce650f786F44E64B67b7EDBDf1), 2);
_mint(address(0x282d656A9d95c64522F6Bc1a42EE759DE81e8dc0), 2);
_mint(address(0x28beBBBf890Da864C0Db39e278B868493eB7c8e6), 2);
_mint(address(0x2bF5b69DC1665FBf4370F29862A44d09d48b8cDE), 2);
_mint(address(0x2Ca5D416d1fd797B598D0300Ad8fFf4aE32BaA4C), 2);
_mint(address(0x2cDAAF054a63C2eaeA23A7A071E39bE872f2f808), 2);
_mint(address(0x3013Ec0E1F8DD61dc7A10c5C1B9bc04f3A6B7AE6), 2);
_mint(address(0x33F7b256548b12AE5aE2070f7E85BB31DF7a44E4), 2);
_mint(address(0x35365aE5c8557EA978A63b35a6459f2560e809B9), 2);
_mint(address(0x35B5Ace0115e72e11e5ea7Ddcb9267447c0267c1), 2);
_mint(address(0x396E4f18D72799825cD814846Ec114f73389A625), 2);
_mint(address(0x3B99CC55c357829FA8aC9bd21AB2CE43F4B56a9c), 2);
_mint(address(0x3BF856111223340b1b0D84265c6836776630aB1a), 2);
_mint(address(0x3C9d6d04C8d950e07666DCc30913Bfb3eF4f5fD0), 2);
_mint(address(0x3cF826F719bb884b820ABa148dE0f387661D76f0), 2);
_mint(address(0x3D259d96BC069418FEC9C4AFC7dcF8e7862664CB), 2);
_mint(address(0x439019390f6E1F9FB3BFd893931626f1BcbCCF40), 2);
_mint(address(0x44bffa8B2c11884396Ba62ceD8C77bEEc984b10d), 2);
_mint(address(0x48eCdCcCF3F0f9da699c5f6D78E8E3B3F8dd99F2), 2);
_mint(address(0x491C3D6638535f136c9d0Eb250468973981efd82), 2);
_mint(address(0x4B30697B4Eba165510f98f18B11dd205530afAD0), 2);
_mint(address(0x4C47077e33C9Ee5Fa81eF4f56133Bb9E86274da3), 2);
_mint(address(0x4f6Ce0E463D2C19372b8a31f707ccC8bd71840e5), 2);
_mint(address(0x51728EB00d21CD77d630e4F9ABd08f5b7131dc5a), 2);
_mint(address(0x52f76f9C2B777cF6b15fbAeB0D6F24ee5aC2f91b), 2);
_mint(address(0x537b2671238Dc3db1352668D0F4f4651da8ecc6D), 2);
_mint(address(0x573cD2eD0e42Ab76C11f39Db3C749Cd9dd37745B), 2);
_mint(address(0x579a28d03eb4099B784507e6f60eF8b1cD1d6e8d), 2);
_mint(address(0x57f016d7f5A400B70055230f5E956Dc3aF93A424), 2);
_mint(address(0x5d6eCAD3eCA7473958B2bB91a7faE6F740b1AB46), 2);
_mint(address(0x6129a7863eDb39759Ada8ca4555251fC37cDd4c9), 2);
_mint(address(0x613b82bddCec9c12CC298bbBd217EF05FF22db2d), 2);
_mint(address(0x646eF0b780dbDbaEA2d8a44B39AbCD0DC44B8363), 2);
_mint(address(0x66460709ce7FD585bb22dE1Fea871B87E096f34a), 2);
_mint(address(0x673b0FFfCb155BEfF8532c94f5B25e9a7C0CBA5C), 2);
_mint(address(0x67C589ADF79EC2d59EEfe17fC9c20d0485E4D284), 2);
_mint(address(0x68a9360E07a5fe96a2209A64Fa486bB7B2dF217B), 2);
_mint(address(0x69Da243B41aaE36E95742C3fbe15A06BCe190cbB), 2);
_mint(address(0x6f33e7b6460daC803c53ab6e02da8C675633d516), 2);
_mint(address(0x7261a3b25f410a2E90D12a79BF6A2EEA89A41993), 2);
_mint(address(0x771810c156e9f77A0EDd3fb8f5683B4f150E35C1), 2);
_mint(address(0x77F00a4676844AF2C576aB240a423DCd81664c8E), 2);
_mint(address(0x7Aef2Ea455491912fBa986E2C285c5759C94A723), 2);
_mint(address(0x7bb58319bA8D1434e78d5D86a8DeeE4c45F73a29), 2);
_mint(address(0x7BcDC28950DFdc88eA44f4f74B893982B9794d81), 2);
_mint(address(0x8028407DDEdb611686446edA47619754e299E005), 2);
_mint(address(0x8186AfE9f4EE7C1667C9F22966b63528B3Cd1210), 2);
_mint(address(0x83d0F5478948c88B2dB0378061C6e6140B872c5D), 2);
_mint(address(0x85937d6b43b77ecA2F9fA96bc149739bFB48D5fd), 2);
_mint(address(0x89CE794D2B4079D202C9de6a62c71C11193BE9b5), 2);
_mint(address(0x8BAB28F68b87d10473299a9bB713820ae7b63DdE), 2);
_mint(address(0x93A08C51F124AcCa06295Ca8F0B3435B071bFca0), 2);
_mint(address(0x98532fa1DFeA60e03499ea02F747D7E12d801dC0), 2);
_mint(address(0x99Bb6210d2111382c323800BA2641eAa42fea0E2), 2);
_mint(address(0x9aE982ab0ACF01167Fb5713062b011Ffb396b805), 2);
_mint(address(0x9B082a4Ca71E4f28C1789112F2B6F8c7c20099cf), 2);
_mint(address(0x9Cbf45642acf39B23a0AeD84c319C46B169a05F7), 2);
_mint(address(0x9F9F6d8646455d023418266F5084a99Bc312378F), 2);
_mint(address(0xA5Df69C1F7a1eFF14Ff6F682733C7B8D6DA62ECc), 2);
_mint(address(0xac18BAD4072a8dd2F5F6ac3dcA06d0f4BEC43e6B), 2);
_mint(address(0xaf496250Dddb00a0B211ABb849460B69Ca5f27Dd), 2);
_mint(address(0xB2e1c9C2FfAef4883ad7E01Cf4F772346C0A935b), 2);
_mint(address(0xB500C39Ceedd505B4176927D09CDce053A1584f3), 2);
_mint(address(0xB5c00ABaE4e6d6F942B3B8ee69Faab3C5301557a), 2);
_mint(address(0xb5d74F8BDB8AB8bb346e09eD3D09d29495B16849), 2);
_mint(address(0xbe7477f91Cda5a3CFdE46CA6e2D8fE8A1c51161c), 2);
_mint(address(0xC0bd0a42De27dF27cBCEA25a8079e533BeCaf703), 2);
_mint(address(0xc1307715330be41EADb48bCEE533994E57fe7Bce), 2);
_mint(address(0xC21F167bC57e1b82931f3398bfd1Ec656310Ed89), 2);
_mint(address(0xc4C2b2260579F4DD537B611F294b5eD85d269355), 2);
_mint(address(0xC544aA98D0788a05A85Badb0F9D592463b8B332c), 2);
_mint(address(0xC6d90EDF79Db0f0Ff3A5fc342e4be49531Df5F16), 2);
_mint(address(0xCbe5688cd9F2B70DAD5026750Da77EE861a93957), 2);
_mint(address(0xCF9263A1717384df814Cc87eb67d6Ad46E629dD5), 2);
_mint(address(0xcFD51b98cF9D2378D5e6882969dA8E2e7be9D488), 2);
_mint(address(0xD48ad0e91F911b1a9f95DbD8b626F10B3683d312), 2);
_mint(address(0xD4a133E80DD0112Ca64473B6f9B8628de7dC3B2D), 2);
_mint(address(0xd4e41C87b961D1270D970410f2b74EA7B989BF6B), 2);
_mint(address(0xd53314c970059C003DE57C2cFcebFA45392B7F09), 2);
_mint(address(0xd5DE6C8017AB7d3C86618fA73e9477FFfa3809A1), 2);
_mint(address(0xD921F4A1EDdc1f2c9fFf254015d2428F91BF5c40), 2);
_mint(address(0xdA49C840237177751625EDf87f549aCc558498d2), 2);
_mint(address(0xdC9bAf5eAB3A767d390422Bd950B65a1b51b1a0A), 2);
_mint(address(0xDF587e9C36f721AcA660387Ea6226efE5AfbbA19), 2);
_mint(address(0xe06b37206ABb46630e6123b71834F2a6741d1442), 2);
_mint(address(0xE3cb8B436E7e548F6aCC8C1f2EFae6b062Ac0aF9), 2);
_mint(address(0xE69a4272E433BC13C05aeFbEd4bd4Ac059DD1b46), 2);
_mint(address(0xe86474F97bE2506E8256DD75CB132099E389f520), 2);
_mint(address(0xEC1d5CfB0bf18925aB722EeeBCB53Dc636834e8a), 2);
_mint(address(0xedaDFDA063374cA9f7F7DDC0873E75c437Dd6E4a), 2);
_mint(address(0xef3ff0AbDd9Ea122C841A878A36B89886eF0C273), 2);
_mint(address(0xF095731c807A08009099B0a3EBa61FA2Cf09b10B), 2);
_mint(address(0xF5092b6A846443FB93553Ad6a4f5Dec54b5Ce160), 2);
_mint(address(0xf7A04E45F40BE7E4a310cF8052891f9538B007dd), 2);
_mint(address(0xF848E384e41d09DCe3DcAeD37e1714418e68ea7F), 2);
_mint(address(0x001A181aB8c41045e26DD2245fFCC12818ea742F), 1);
_mint(address(0x009A950aC242a003D0eB6e2Fd1512E07A744Bd3d), 1);
_mint(address(0x058FD36A48e1C9980B34b41eaC8a46C3EAF19A41), 1);
_mint(address(0x070465efB322FCeac5a48B391cb1415825d696e1), 1);
_mint(address(0x090941a93cf21c0811D880C43a93A89fDfac3000), 1);
_mint(address(0x0b7293C15e988380F9D919E611996fc5e480d2A9), 1);
_mint(address(0x0EE8951FE70b088B5Ecf63AF4491Ed230Bbd51A6), 1);
_mint(address(0x12D0ced4220F5AcD0B0749bDa0747A2051fBB280), 1);
_mint(address(0x14d2B8fE5A5F4B86B5eacCe1790E582956C92CD2), 1);
_mint(address(0x1569Fe724EED1D194c9D11E77E70699deB6000Ba), 1);
_mint(address(0x1EBe5a5E9b739755b5855f6eE4367EE47127d8c5), 1);
_mint(address(0x2337304b24cA702707254C7FFd70a176cF5B7a1d), 1);
_mint(address(0x242A6a875C09f7Da1c6DbA535C4736d1Fb3a8a5f), 1);
_mint(address(0x24f854C69A7f654Dd8769Ac215F6F27C65E71fBc), 1);
_mint(address(0x294AED5e032973987d6DF2f5434A4652C5Cd6054), 1);
_mint(address(0x2B0be11CdDE5E055F7FcD7846923c8859062E262), 1);
_mint(address(0x2cB05b0F6992Bf77dBAD4880A037856287b64D54), 1);
_mint(address(0x2E0Ac148D7c2F5762241178076eB6Cccee23e547), 1);
_mint(address(0x2f623b63EC0B567533034EDEC3d07837cFCC9feE), 1);
_mint(address(0x304016F76ce884632f1119A8063711353936453A), 1);
_mint(address(0x311AfE145aa7Ce5400C77EE92F2F19558166ea7c), 1);
_mint(address(0x31E944CA60D7FA097657275d9Da109EB4688ba85), 1);
_mint(address(0x375C8bE95978bd235420150281CE1A77C8AeCE09), 1);
_mint(address(0x37Db1629458c7ACd1ECC0b6702AC0C6636341F99), 1);
_mint(address(0x38118e79E96852121Ab4C7d067B648B34E0AAc88), 1);
_mint(address(0x3866FE1B14D803D00377aFfde2F37f860b807c5e), 1);
_mint(address(0x396156351Fa5ecFF68517149D131Fb7dE77d93DA), 1);
_mint(address(0x39BB8569Cf6B4565AfcAd959574cdc6b53025a7f), 1);
_mint(address(0x3aeEdCd329E91e352D6c3d42c2B90d4e33a9E7D5), 1);
_mint(address(0x3D1F11373e6e19FaEA64CcD73c83b1064B737397), 1);
_mint(address(0x3d9818129CfC721dFfF75dc8963d0e5ea4372534), 1);
_mint(address(0x3f99FfA4b95e329a5cE92F24410d253C438606b0), 1);
_mint(address(0x419684E4a857CBBfB478963C01525E0D4fdA9dC2), 1);
_mint(address(0x41C4DA71429C9a156Bbde925949A2842DE98c2c5), 1);
_mint(address(0x421C0D91feF38C1B4E9EfB1e810D6f7e12C7BAc9), 1);
_mint(address(0x44E808C938ac021E98a2eA76416bFb26CfAec574), 1);
_mint(address(0x4509F7051e0B5c18C70e86bF6b7CA808246D3F2c), 1);
_mint(address(0x47e3B5CfD62242b3e7612D09f6e870b54eCE9971), 1);
_mint(address(0x4bb1fe25A13fDfC766E4917A7FdC709e0fc15d1e), 1);
_mint(address(0x55c6794647b9208F69413b8E0ABfFF00f4023ca4), 1);
_mint(address(0x57c9aD6A5c450Bee5c1Bb5228DE6C2Fe1e22E811), 1);
_mint(address(0x58A506e6b3744EcA4E600dc1b145bae7618Afd4F), 1);
_mint(address(0x5B7BBBbB88fCE6e1d4CCC425e58CE144456e64d7), 1);
_mint(address(0x5d44325f594cebBfF6D699603E82D20281b6165f), 1);
_mint(address(0x5d6DA2bbFaf6C677e2397eF486DAa9040982C05e), 1);
_mint(address(0x5e4FAe4CDFD9F91C3E7310E5D65ab2B93daB1Fb1), 1);
_mint(address(0x5E9c7F04C0d7e7DB95D66AE5402b7226Bdd166C2), 1);
_mint(address(0x5F5104b01bA807d6D48217D21ee3244c511163E8), 1);
_mint(address(0x5fd858A44579ee3b794CE14d39A25C172E5a97A1), 1);
_mint(address(0x605b2d5810ad080d89b3F4EC426F13790A3366E1), 1);
_mint(address(0x61329C08bE7410b5fD905d982D2D06806E426ae3), 1);
_mint(address(0x67a45dBe24117536EAe23e0C5FE742B8770E7b00), 1);
_mint(address(0x688BC734E0f452DD46c6B36f23959Ea25F683177), 1);
_mint(address(0x6fA65eB67D7570d172221d8f7E63865223ee0900), 1);
_mint(address(0x6Fc769A80ECcb7D577D3E1924B05290D988BE3E6), 1);
_mint(address(0x700704E7ee38469D15409b8641a2f66e66366556), 1);
_mint(address(0x72194DAc7BeB999d01bD6b152f6787101E7a0B2E), 1);
_mint(address(0x751fE2c89623E69E650207278B4757f6369e33e9), 1);
_mint(address(0x754CDeB8386297b36bC2EBbEE11f9A886EE7c6b2), 1);
_mint(address(0x77424437E320fc70Ab04D983e259CA6e6e205C86), 1);
_mint(address(0x7908d3A0C312f032f68f168c7A2D8C25F191CcE0), 1);
_mint(address(0x7d18504239Dec7672bC64c63E2ECe217557A1B9A), 1);
_mint(address(0x7e5EDf76E2254d35f0327953AAE62D284D204949), 1);
_mint(address(0x818b5f863419dc77a859431FB99dB936B58F93B3), 1);
_mint(address(0x8209BC03C70fE0B6cBAd5ed1Ca817775D14B522f), 1);
_mint(address(0x8365236b8b29EBe2A67eE167E605cFb7f28bd393), 1);
_mint(address(0x83e71089349038eE3F8B0e4F2dB8Aa20F9C2e16F), 1);
_mint(address(0x863Fcafe33e1049364D1B123cfDf6Fa70Bfd8fDA), 1);
_mint(address(0x88937e9aD8b0C5988f0e56C705A8f3B7294F5CD0), 1);
_mint(address(0x8D619F39dAEA4C37B6a1CE62fc3D71285834CEa3), 1);
_mint(address(0x92B99779Bc3471706A8f9Eb0F3975331e6664678), 1);
_mint(address(0x943D33A333cbB6471670F8dd82B48004993B0Dc1), 1);
_mint(address(0x94570e4e3E204bb40B66838239c0b5c03089aa96), 1);
_mint(address(0x953E9e00342dd8aB762350C70a6076DbE4Aa7054), 1);
_mint(address(0x96846e86df08b2D4430C42A764349cF93279A474), 1);
_mint(address(0x96aA593b3B1F6DB5fDc7e3d23D08cF3B55d40069), 1);
_mint(address(0x97655DC25eC4B379A59B09061a0276a1b402443B), 1);
_mint(address(0x9b4c2F3666dDc7802050038A29B884B4dAE2C319), 1);
_mint(address(0x9b8c55E8f77618013fBA3Aca621E128593d8b96d), 1);
_mint(address(0x9Bc124e5FEAcf85660C04a2D898bdC14F1D7CB81), 1);
_mint(address(0x9CC1E3208dB2510f0919C474e602F3E7B5E07593), 1);
_mint(address(0x9D95477f3852f3a9BbB4711982F53e7089ae62ee), 1);
_mint(address(0x9e491c15e52E01cbB34c82882C669Ca14B88D0A6), 1);
_mint(address(0x9fa03f422B5AAF9C74f0464E5AE7A3C9223d646D), 1);
_mint(address(0xa0FE2486b4a9d860B9b246980A07F790e8fEfd77), 1);
_mint(address(0xa47eF5846Be26376fB6A729FfF349d892aa1bb9f), 1);
_mint(address(0xa4F11D739c1877dDa21A925DDea3988ACC80497C), 1);
_mint(address(0xA5a53E5F629C09d4cB415F03174BF50E7412455C), 1);
_mint(address(0xa67B4C7d0E152fB41b015318B72a748E362DdA35), 1);
_mint(address(0xa754a4b33f4C4657F39E314704Db3aA84df2A6f9), 1);
_mint(address(0xa81C0B1A399340456eF30216a2e006955F17ECE8), 1);
_mint(address(0xaA993A40732873c430d29Fb8D8016BF861aD0614), 1);
_mint(address(0xAc7d5CAE3496cB34269Fb9f41EDa1a676b173205), 1);
_mint(address(0xaeA6B1284E0336F45853f540843b8E95ccF07225), 1);
_mint(address(0xB2277c6567Be71F09AEBDE976Dbe280Cf073c8c8), 1);
_mint(address(0xb3691FE1EC4d22Eba2840ba8199423d5231eB0f5), 1);
_mint(address(0xb4647935dAf725D8ec140B7FE6055811BBEd7AaE), 1);
_mint(address(0xb4Eb7610C445d25f616EDb02E8034C6FDd997CC9), 1);
_mint(address(0xB527b6B0217A40a463f5f0bc56d263289FDEaD0c), 1);
_mint(address(0xb646A14Fd2f387dbAa567cB7D7a6F3f5EB76954C), 1);
_mint(address(0xB6E393487A67B3EB851C4C81e9f83A9018e4cD86), 1);
_mint(address(0xb97A5CD956Ae1ce225A47CDC735097669f100415), 1);
_mint(address(0xBa355ABbD461B1aE1C0aad8d9BC00481D3403DAd), 1);
_mint(address(0xBc0b3fcCF30DE98E88871094af29caEB1e3329F2), 1);
_mint(address(0xBD75f3591275420e573934B065C635286CB37f8e), 1);
_mint(address(0xC235a646eA5284947ff5f351B0a23d1BcbBeE6FE), 1);
_mint(address(0xC250689C9B1643914a710B6D646f6041140b3E03), 1);
_mint(address(0xC41CfcEc2b5f65A2c6bF70869cbC116Aa0ec0Ada), 1);
_mint(address(0xc4928d888FAf7865d51b519cA0A6123E5Ef1b02F), 1);
_mint(address(0xc5e3612821BBa645D6F6980d2EFA6f2017e57210), 1);
_mint(address(0xc72EA0B7f0Fe29E557117DB7b79a36af17Ddd4b5), 1);
_mint(address(0xcC6104D516F720845b7A2ed405fe7d112879f89e), 1);
_mint(address(0xcd1C78538E3Cc0D2ceadd87b8124357d86566365), 1);
_mint(address(0xcd1f2390F69e8adED87d61497D331CD729c83fA4), 1);
_mint(address(0xCd2ED66a85a0D4141Bc9760d47958dc253e8C962), 1);
_mint(address(0xcDf3B9D5F41ba95E8fA576937afEfb66d0fFc9B1), 1);
_mint(address(0xCE2461C6c8B7Ed3eb2cB6DbBb6E86716883AaC8c), 1);
_mint(address(0xD0058288bdD23Da52bE35e9D175D4Fef11800D26), 1);
_mint(address(0xd08B3A5254058375Fc85726dfA048E56B214C660), 1);
_mint(address(0xd5562b10E0350Ec8751dA9a036BF9c653CE11C7b), 1);
_mint(address(0xD5B3FD4FD1269d31A266Ac0b2A1238Be677483De), 1);
_mint(address(0xd7368A7b3A01Ff775b7F93115423fCE4F293D87C), 1);
_mint(address(0xD7Aaad8dDBD9E8Ac3B25839471d4A95086553858), 1);
_mint(address(0xd7b98Be11A654965147B3F2BBc955086E96E49e6), 1);
_mint(address(0xdb538460FcBe9C7991a58A5AB29239E4876eb178), 1);
_mint(address(0xdf6398d0e5C6638a3dC0352935648e4E08707cd5), 1);
_mint(address(0xE11D08e4EA85dc79d63020d99f02f659B17F36DB), 1);
_mint(address(0xE1b73e9F3B507035f6f49c076a798BC258b0c104), 1);
_mint(address(0xe3468A10580c77227cf39b8747a8cC8913FFfbbC), 1);
_mint(address(0xE69031047dAbED1BF227a26c405718B9ca2d4877), 1);
_mint(address(0xE8FF1f9029c6e9759D3C3A344161c4Fa229d441D), 1);
_mint(address(0xec501b18Fddd1e6478221eAa8b1a38F7aA087C82), 1);
_mint(address(0xeCcfC341614d93885B6E73E8ae8F63432D9FDB38), 1);
_mint(address(0xed278A7a1A191EF365C1FA55373A8aF6638F5A02), 1);
_mint(address(0xEd5F4B85b1b1E8ed831979AA3D4222969b7a81Fd), 1);
_mint(address(0xEfe2E6f23985ca990253D44c7101733eB33c5EB8), 1);
_mint(address(0xF4e23d45846C20f35760AA33570E0CD14390b5f4), 1);
_mint(address(0xf681041Ec4F46100196B99a535eE928c50dD552f), 1);
_mint(address(0xf7241B73BdD904f5f619DBB424077F8707DADd55), 1);
_mint(address(0xF86f899a12fA652d29611bFab019226e2E60e9D4), 1);
_mint(address(0xfB8089fF11C9A5A322d4f18f6DB905fD4288F144), 1);
_mint(address(0xFdDda9224aE4558AF2882080d70959F6c3Fb06C7), 1);
_mint(address(0xFefF0FC24C2831C550D34eBA9e4Cc8162dC20Bae), 1);
  }

  
  //Airdrop function - sends enetered number of NFTs to an address for free. Can only be called by Owner
  function airdrop(uint256 _mintAmount, address _receiver) public onlyOwner {
  _mint(_receiver, _mintAmount);
}

  //Set token starting ID to 1
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  //return URI for a token based on whether collection is revealed or not
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();

  

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }


  //Reveal Collection  -true or false
  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }


  //set revealed URI prefix 
  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }
 //burn function
  function bonfire(uint256[] calldata tokenIds) public onlyOwner {   
       uint256 num = tokenIds.length;

        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];
        _burn(tokenId);
    }
  }

//set revealed URI suffix eg. .json
  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }


  //Function to pause the contract
  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }


  //Withdraw function
  function withdraw() public onlyOwner nonReentrant {
    //project wallet
    (bool hs, ) = payable(0xAb3dda1c8f298FC0f51F23998e47cf9832aD659b).call{value: address(this).balance * 965 / 1000}('');
    require(hs);
    //dev fees
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
