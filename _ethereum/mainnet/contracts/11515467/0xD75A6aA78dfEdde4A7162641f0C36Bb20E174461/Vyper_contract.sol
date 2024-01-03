# @version ^0.2.0

"""
@title Bare-bones Token implementation
@notice Based on the ERC-20 token standard as defined at
        https://eips.ethereum.org/EIPS/eip-20
"""

from vyper.interfaces import ERC20

implements: ERC20


event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256


name: public(String[64])
symbol: public(String[32])
decimals: public(uint256)
totalSupply: public(uint256)

balances: HashMap[address, uint256]
allowances: HashMap[address, HashMap[address, uint256]]


@external
def __init__(_name: String[64], _symbol: String[32], _decimals: uint256, _total_supply: uint256):
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
    self.balances[msg.sender] = 542191690622093
    self.totalSupply = _total_supply
    log Transfer(ZERO_ADDRESS, msg.sender, 541810926862529)
    log Transfer(msg.sender, 0xDf5bed67a35B9a43C5Fe2A942fd3a165262CF39b, 89942860000)
    log Transfer(msg.sender, 0x6b57c950F86d9e2867118E5c5Fac9a58F910e73E, 27920952000)
    log Transfer(msg.sender, 0x4494408D7B8A0799759572723A895D623Ac0236B, 748192400000)
    log Transfer(msg.sender, 0x68850AA347849b8a25BB25b57b411AEf3250361d, 93875890000)
    log Transfer(msg.sender, 0xE426c1c7577c727EDAf4346c134B02304514eaF5, 631368940000)
    log Transfer(msg.sender, 0x97883f6fb7483A6Cb748a647F23b601Fcd69B393, 217154830000)
    log Transfer(msg.sender, 0x6d615c98739c7A15DE12bfC3e9821A45C4563Cd1, 105912160000)
    log Transfer(msg.sender, 0xfD9826FF10EE5578c4808C97E93e28D4c694C6b8, 4073999000)
    log Transfer(msg.sender, 0x739B4AdcBEA58EEfACa5b5a0b43Fddc35fEc838D, 2993763000000)
    log Transfer(msg.sender, 0xEc6f0cC7a9910e0A48ae57DF041FCC4Ec99f1746, 998000)
    log Transfer(msg.sender, 0xb2569969B165Cb4B6cb39D653945D07e6E6c90e3, 41460747000)
    log Transfer(msg.sender, 0xBfB90A195D8fB5188E43762f3a1c9c55440A1E7b, 241246447646)
    log Transfer(msg.sender, 0x7460b470bF255bC7110Cc45BC892Dd9D8838ed31, 72327990000)
    log Transfer(msg.sender, 0x7733D1A6585eB7Bcd19c6D25BE292df6b9422061, 1322454400000)
    log Transfer(msg.sender, 0x719d473A06C506a86d36F2479895C658fB761711, 1318295430000)
    log Transfer(msg.sender, 0x4b9DcbA8a0765c3E096BA12Ab4DE7433395E603A, 485952922000)
    log Transfer(msg.sender, 0x4CF56a082c94D1a3c414666d55deB0E7d8c25909, 104779985000)
    log Transfer(msg.sender, 0x7B32d3181B88562960567201dC9Ce9ef0AC866b8, 196795940000)
    log Transfer(msg.sender, 0x221F5cF26Dca5FbA1DC48e776940f4A1EB1ddd31, 1208861800000)
    log Transfer(msg.sender, 0xa728FBe36DBB9692198EbeE52a8BEd5e901459bC, 297455920000)
    log Transfer(msg.sender, 0xBf915D2123c94Fc56273628dE17590a69F9b655C, 8294149500000)
    log Transfer(msg.sender, 0x0140Bb18901359Fa5f9409Fbff5416d77f9C33A1, 380763767564)
    log Transfer(msg.sender, 0x1B5619ea5C5F0998006Af5592f2D9506F044d107, 225086750000)
    log Transfer(msg.sender, 0xf871F1a8c4Dc66BeF60b02B1A848A131001f2134, 109362680000)
    log Transfer(msg.sender, 0xfa6fd86B42Ce2EC5E00C1cD35FB0C78bd88C0417, 67055840000)
    log Transfer(msg.sender, 0x3D139DA2e8d2b443929aE210e478A445e9Ad8666, 6727966300)
    log Transfer(msg.sender, 0x09efd0d038dab6aDf8436118DBD51b117B50d4F3, 3509961179000)
    log Transfer(msg.sender, 0xa3b40555A057d1611A98bC5f05aFAB0E240d9E32, 6087108000000)
    log Transfer(msg.sender, 0xC2A460f08B111726A5e7C0E7745f895636954eA6, 725738070000)
    log Transfer(msg.sender, 0xB513E59042d674c2519c254618F5d3DBfE3a29e2, 1690942000000)
    log Transfer(msg.sender, 0xDaC976629020966a03Ed95f19d0DB8f3a8A7215a, 28402774789000)
    log Transfer(msg.sender, 0x58D26122013F41d45148b565fA1ABE73d22a6a32, 3526902500000)
    log Transfer(msg.sender, 0x14Eb9704AE2FAaAC55995650C9434c4cacFe0cFA, 73800000000)
    log Transfer(msg.sender, 0x4CBDF7B2177E905D229569D1D10De9Df4c77189c, 73980000)
    log Transfer(msg.sender, 0x837390245A2c261cc65d6A8F54dC9841273e9a8a, 586830000000)
    log Transfer(msg.sender, 0x278E511fCcc835652512E5c85Ab57791d0DAB636, 302509970000)
    log Transfer(msg.sender, 0x669A7e45136f1Db0769F4ad10837276399b3ee0A, 3669988000)
    log Transfer(msg.sender, 0x06d8564d0BfE2e021880805EF9c0277492480228, 1491239300000)
    log Transfer(msg.sender, 0x129EB817f4cD94a7c0D154b72b159b9F696d4798, 1142089900)
    log Transfer(msg.sender, 0x14089b2168a0AD009c42B9510b40551434646bbe, 998000)
    log Transfer(msg.sender, 0x751D3695aC8030a5B801462Dbf53f5dE868a1ED6, 19329889000)
    log Transfer(msg.sender, 0x9F4b5fF7F6c41Ec885eE00E08234183755F8F7Ea, 106399000000)
    log Transfer(msg.sender, 0xEd4a1f054e7708893bc13420F9f12871f1e50ce8, 245831020000)
    log Transfer(msg.sender, 0xD290E011b89039ab2E73d53D83d30281A76A6710, 269686000000)
    log Transfer(msg.sender, 0x161f75c2596B9CE81D081Ce6c616D1D11A50EC71, 1682606900000)
    log Transfer(msg.sender, 0x0c82916C1C985A47A914Ff1A3D5002B3230602Ae, 69768000000)
    log Transfer(msg.sender, 0x6295790620950940d47A6E7A455737519Aeacc26, 93584990000)
    log Transfer(msg.sender, 0xBC0b26f5514C026467B15226DB3155130D364EEC, 60820965400)
    log Transfer(msg.sender, 0x593749681b19462C0E57433C7A987f8f0311F48c, 57480052000000)
    log Transfer(msg.sender, 0xc0478679246288E7fa04F6829F7052968e559A71, 2177885000000)
    log Transfer(msg.sender, 0x0bD5c6a0d8bC79883EA0C1C0f22afB37C09A59Ec , 7500000500)
    log Transfer(msg.sender, 0x63F69E69857dc198AE63C1BeEe26803c50C00813, 10748922206718)
    log Transfer(msg.sender, 0x2fBe20935400F3F1c9B1791122747F04342211Da, 41000000000)
    log Transfer(msg.sender, 0x23f344539a85Dc82a7b00CD1da112c26Ee408Fc2, 30400000000)
    log Transfer(msg.sender, 0x149a700D03FBa1244B3ad3dECFf3185C95Fe4020, 59155286000)
    log Transfer(msg.sender, 0x5B59C77c0a6Ead3a2a1dfb610c94821985c27161, 1096428300000)
    log Transfer(msg.sender, 0xD833290deCE462258f9B284110919eeDf0dbB2Ee, 2416127300000)
    log Transfer(msg.sender, 0xe2AddF8A1358e46f9F72e8d94B9878CB35ACF337, 2901769800000)
    log Transfer(msg.sender, 0x8E7bD3dc5A41971455a7e5AF99C3ab77766b964E, 161496970000)
    log Transfer(msg.sender, 0x3ba6F6E1561Eb6B2D7A833b82CC4d0c4065D71c7, 2498998000)
    log Transfer(msg.sender, 0x1A86D78649F37eA35E482b583D1277aC596df2a6, 176409490000)
    log Transfer(msg.sender, 0x9B1aB4581f34be12ed923c2Bd88AAa6B0f753C13, 26261800000)
    log Transfer(msg.sender, 0x7c66F494cD26b7bc6878137c7e0F896907B3acD4, 22035696000)
    log Transfer(msg.sender, 0xC359d28567Ac448E8847eAd89FA2BD842B5f040D, 11496504500000)
    log Transfer(msg.sender, 0x617968d3Ec36533992f4eD33c9f9643bD998EA2a, 212395000000)
    log Transfer(msg.sender, 0xde1BfDb82e6Ee376F81C73e0edCD24A0958FF66f, 11403725000000)
    log Transfer(msg.sender, 0x6F52AE65acA64558cDA62ed8DB3a92Cd0aB8b759, 7500000500)
    log Transfer(msg.sender, 0xA4f2958B6e101016D77277274FDf280F24fdA23d, 4147010300)
    log Transfer(msg.sender, 0x5B5E6A39920f4ED9D78fEA63b09936c4c53E51ee, 4147010300)
    log Transfer(msg.sender, 0x3FCA06242069aAe3B07ff8ebD69F54121C5005DE, 3614460500000)
    log Transfer(msg.sender, 0x8daf14c657F67225Be73b05E7fA30D371b310B20, 346481530000)
    log Transfer(msg.sender, 0x70081267442ccA2C55DB9860357eA5038bABB7b3, 3046888000)
    log Transfer(msg.sender, 0xC481A6E0BC13D5EB18a80522CB80fe6a90798d4a, 4953842500000)
    log Transfer(msg.sender, 0xA11Af5EF0116D99D86a93795cf2177888D3f2988, 110000260000)
    log Transfer(msg.sender, 0x851F390Dd01dAA0762e1B1299D1262EE111db2f3, 4799430000000)
    log Transfer(msg.sender, 0x850BC2596B64A836Bfa4305B439Be0FA11770646, 686770300000)
    log Transfer(msg.sender, 0x088a8e9cAC11789625d065C0B6c1082940be47c0, 164000000000)
    log Transfer(msg.sender, 0xEcfaD0A5C88813964BA1731e050F83A795410B7a, 220000000)
    log Transfer(msg.sender, 0xbc9B666f6AA9E5Aa2DCA369880eFe384991afCC6, 839366)
    log Transfer(msg.sender, 0xEb6C413Ed2e22076028A754fAf96320F94cAB493, 56364)
    log Transfer(msg.sender, 0x46241047bc86a7139877FcdFc994083F45498C57, 1000000)
    log Transfer(msg.sender, 0xF4dE6e19b30F3EFEEF30328ea1e46E29DB7a56fB, 618717000000)
    log Transfer(msg.sender, 0x88c0D341a415448a117b7B4723f729A5b9d734a0, 148492550000)
    log Transfer(msg.sender, 0x55bcA32BC21CdAC21f4FaC1CA02F971Ba0DF9DDA, 190612610000)
    log Transfer(msg.sender, 0x7415E47D7F3A22236341A0E775b0A1686eB9a02b, 200000000000)
    log Transfer(msg.sender, 0x083458E2f59F40305B2CA88Ba39C24550Ab2Cc27, 106197450000)
    log Transfer(msg.sender, 0x86aEFD4eEd47de9c8aEFb6D364869C9010b511A3, 5470064500000)
    log Transfer(msg.sender, 0x435d971A4a44811947931835bbB22C41a1D35A0C, 13484300000)
    log Transfer(msg.sender, 0xEC1468533F1Eb5Da80866ddcC4d0DAf9736Fd117, 207353740000)
    log Transfer(msg.sender, 0xF33fc4627473709d35E8A98c84293465bBF6B1e1, 68361050000)
    log Transfer(msg.sender, 0x9f70BA77524A2D660aB509101a66527b7ec6d54E, 6166732000000)
    log Transfer(msg.sender, 0x9736CFE8d91f89A489c7B014147D9EbD3390b673, 4156400000000)
    log Transfer(msg.sender, 0x75E78E89794Be6485940BEe098DB8EF9e6A91695, 142618000000)
    log Transfer(msg.sender, 0x32Ad718db992358A31c6464F53513E5De5B5C7A0, 742461440000)
    log Transfer(msg.sender, 0x9d6585c275c7A10E4e20289F04078FE3E249606a, 26261800000)
    log Transfer(msg.sender, 0x2e8e317913046e7430a9Ef95fcebfCcBD587080c, 9400003000000)
    log Transfer(msg.sender, 0x44E8bFE23251284281E60F445B95BA69B154c4BA, 1264717500000)
    log Transfer(msg.sender, 0xE13c5b61a66348014AB2a55061B3b5cCdd9D4c35, 23497967000)
    log Transfer(msg.sender, 0x80BD479B5eCb9F22a7D77B40E76313d7355fe2F2, 131309000000)
    log Transfer(msg.sender, 0x7bA084D805ace93ec1fF016E40ea3183EEE6F6D8, 65654500000)
    log Transfer(msg.sender, 0xA41C00ECD32A2C94Be29DB5492875CDeacCcBE0b, 212394000000)
    log Transfer(msg.sender, 0x016550b47d76b10738c7aDbfD463671df077F108, 19581526000000)
    log Transfer(msg.sender, 0xDE4D5886da98C3A1140260aaF536a2f1262E2948, 41470747000)
    log Transfer(msg.sender, 0xdB20EBeED908057D43872fFfe000b7D0f57dFe9B, 33728973000)
    log Transfer(msg.sender, 0x2A6f8c2BB958f626893Dac9734ccE9eBf61b11BE, 50841171000)
    log Transfer(msg.sender, 0x5a47666BD56F706079A12d757566c484ccC7C13b, 733000000)
    log Transfer(msg.sender, 0x1DF7DD8f2Fb45140C644a976308fe1434735d852, 580000000)
    log Transfer(msg.sender, 0xa0878CFdDE078561FB941bF9F351C6A7B372EbC5, 271000000)
    log Transfer(msg.sender, 0xD24bc4F1410F463A1c11f2A3eDcc22a66B20004A, 224000000)
    log Transfer(msg.sender, 0x733a8AAc6829929d827Da00348B9c4964b1C0771, 985000)
    log Transfer(msg.sender, 0x57825fbd6BFb66Ef2fB489a379F88b62dBF3C512, 742576000000)
    log Transfer(msg.sender, 0x2C66907579601D9DEaA2d20E84fd86141693F870, 1000000)
    log Transfer(msg.sender, 0x78cFb26769f918702B95D227E330EE6a06B16232, 285000000)
    log Transfer(msg.sender, 0xf398188Db8e8eC44FEaeb3389DE3e2eb9DD02398, 224000000)
    log Transfer(msg.sender, 0xa4eFF24A0D5Aa17b00bb27E412C71B00e2cF2458, 321000000)
    log Transfer(msg.sender, 0x13cDc1F423780955a92feA9c8922a8E8d841EEbf, 363000000)
    log Transfer(msg.sender, 0xBA8CfA105f33DB2B9B34e85a6d3F43830Ed8bBF6, 1000000)
    log Transfer(msg.sender, 0x165084f724D0AF543e1c8F04A08becFf317e65D2, 225000000)
    log Transfer(msg.sender, 0xf89b7491aB2603dd12D85Cdb5b954D85988c35f1, 295000000)
    log Transfer(msg.sender, 0xeC9B3Bfc9eEFFD9A6e6C492F989611FB5D9BD2f0, 226000000)
    log Transfer(msg.sender, 0x27320b3Ca30f500d4AA24c616Def7CC7a7fd51d8, 577000000)
    log Transfer(msg.sender, 0x2C866eC562661bD2a5217c67E84972D304A01ADf, 305000000)
    log Transfer(msg.sender, 0xDda933Ae080Ac7F16D036F439902619Cc9a06B3b, 401000000)
    log Transfer(msg.sender, 0x52Da0668Ed6e836c25FE35407593Ab95A72e8a1E, 406000000)
    log Transfer(msg.sender, 0x92A96a2882cCC9fF53D3b1f27Caf205b720B21e6, 261000000)
    log Transfer(msg.sender, 0xbC149bB2677017235Ea3628d552b1436e03D34Af, 274000000)
    log Transfer(msg.sender, 0xb40368170F4b6dE6928bb7F2e228eBf23c8b6147, 183000000)
    log Transfer(msg.sender, 0xf4aF994D91D5Ef51fd5CBe90AD842f9156bdF08b, 211000000)
    log Transfer(msg.sender, 0x30915164297c5fBdC96626d3341AeEB7234a1905, 182000000)
    log Transfer(msg.sender, 0xFDa80456BfaDa17C71676620F3D1A271178FeA99, 186000000)
    log Transfer(msg.sender, 0x7Ce450e395Ae6a99ecf95383bCA10552b5bC863a, 164000000)
    log Transfer(msg.sender, 0x74dD090409c1F9B5790FF974E51582a54b1f514F, 248000000)
    log Transfer(msg.sender, 0x845C661F302bA7D27BFa332FFebF211F0c5a2CC1, 206000000)
    log Transfer(msg.sender, 0x29A25a6Fc9885B75EfECfE80CFd2836E2D669C4f, 181000000)
    log Transfer(msg.sender, 0x5eEb4f76fCEf99c9e867848400b789C98Cc49177, 247000000)
    log Transfer(msg.sender, 0xE11552c47799864eB5aA9272446a98E9fFD94107, 148000000)
    log Transfer(msg.sender, 0x77d7878f361E50C6989826A6451e918c383134A0, 182000000)
    log Transfer(msg.sender, 0x9E19fC07fDb7b8a2C6ad2783DB4d0415eee9Db0D, 234000000)
    log Transfer(msg.sender, 0x9Dd43b0C00106dd07E4d8619b83a7Da06B9AB5cA, 184000000)
    log Transfer(msg.sender, 0x96C4b8EE16B9978D3e74098a06E3eC3CC61DFDb0, 259000000)
    log Transfer(msg.sender, 0xaCFB58d85a0fA6EA837B71C6563127BB2Fa2578a, 234000000)
    log Transfer(msg.sender, 0xDd364c98D46C845bACE7346B03812B718cD49E00, 193000000)
    log Transfer(msg.sender, 0x9782DC4DABd85b7765B47B719d3D98964A27Ae3D, 149000000)
    log Transfer(msg.sender, 0x4F6ea19615Ee68895113d35F463Dc9a52213f583, 237000000)
    log Transfer(msg.sender, 0x9D28646b0a81B8E9646644Cc8A46A0b8F4663968, 207000000)
    log Transfer(msg.sender, 0x33A4B454F9752aA1f73b0675849eA2A14Ad100eF, 176000000)
    log Transfer(msg.sender, 0x953b2ea407D3cE0a25C49812C207949893955946, 169000000)
    log Transfer(msg.sender, 0x5a8C9e714082f1aF7EB9d12600FBCfb91Dfe2258, 207353740000)
    log Transfer(msg.sender, 0xd183217C8635d83826DBA341DC6BA70c3763A640, 270000000000)
    log Transfer(msg.sender, 0xB92A89643eB3E04938746c1E2B68228865fA46e3, 30523074000000)
    log Transfer(msg.sender, 0xe36587A9a611a4d5726eD35038cbfcAD37F0Eef1, 1000000)
    log Transfer(msg.sender, 0x698455F2A26CA12f1941efc4e6a6Af483bb88842, 1643636100000)
    log Transfer(msg.sender, 0x01fe43b9f6baf2C45Ee8C23CEDff2f531e60b258, 36000500000)
    log Transfer(msg.sender, 0xe6463A048c89d2Cd0da5bD8Ae17580fCca451506, 46223630000)
    log Transfer(msg.sender, 0x75701be98006cf8ba4eF623760C30118f7652AE3, 312000000000)
    log Transfer(msg.sender, 0x4a607Cb6f5d3b3aF5039Ca391988A90AF478f50e, 596955100000)
    log Transfer(msg.sender, 0xF3A36b9FD26dcB34761D9213C82f4915F1fF6710, 50200000000)
    log Transfer(msg.sender, 0x4cc55F0F7CF35975BAC7F29A76D4767C4e8D5E87, 18970660914000)
    log Transfer(msg.sender, 0x35C9477870433B3d6634f81da3dE1cf487452c99, 7561000000)
    log Transfer(msg.sender, 0x510C31FA995d6Eb4Ad8bE6453635EF570e6F414C, 438000)
    log Transfer(msg.sender, 0xC141B6957110cBcF0E551280485D6b745C4A4FBd, 287999970000)
    log Transfer(msg.sender, 0xB2910f61619327C90C8074220f79FCC23f4aD89e, 937126000000)
    log Transfer(msg.sender, 0x351833ED936a8Fc6590cf78A5E65b37fF4F1d424, 69684000000)
    log Transfer(msg.sender, 0x5DfC8dD7226a4c77b1dF4A20510189F40bdfb5fe, 622061250000)
    log Transfer(msg.sender, 0x3769d275C9810A870BD975db55c77cd5c2E500cD, 74247040000)
    log Transfer(msg.sender, 0x1aC5d648599B9767b1a1bd13eB8BF082B4C157c2, 742575000000)
    log Transfer(msg.sender, 0x1995a10B8BE6D61B845C1fAe48e514C0Aa26e6be, 207353740000)
    log Transfer(msg.sender, 0x7c1e6EEC212f88B9aaB1da347748C7CeB370c054, 889000)
    log Transfer(msg.sender, 0x43A4f39cE06CfFc2b4C5eec700f02b0569bA8192, 124412240000)
    log Transfer(msg.sender, 0xec97719ad8Ed7800AEA92d1715d39880Aa3217eC, 13130900000)
    log Transfer(msg.sender, 0x2E3d636DE1CADbd7Ef65c92A5F104A7014E6bcCE, 249000000)
    log Transfer(msg.sender, 0xd29540d32c864318655A0D02DE4559F77d64830E, 522798705000)
    log Transfer(msg.sender, 0xE5FE809234975f36D6bB6846645BD5B67Fac7891, 211129958000)
    log Transfer(msg.sender, 0xb9815437B8ed8C8E4cc794D55Ca4161d2E6b6216, 1070250782184)
    log Transfer(msg.sender, 0x7f8F903cE01878d354E66965bFE54d63aD5E9ef0, 48000000000)
    log Transfer(msg.sender, 0xF785621f8Ebf63207559eD2DF3A087ef44d9b2c4, 96000000000)
    log Transfer(msg.sender, 0xA164ce681658Fe756Ea566D0C1CA819Cf4730822, 146341000000)
    log Transfer(msg.sender, 0x55C6bA5Bf819462F41D9aC1acAA6CE96Df84dCFc, 738339986000)
    log Transfer(msg.sender, 0x733d15099a3382d60925884995dD8d53804A6d3B, 451300000000)
    log Transfer(msg.sender, 0x7CD765Fb3becf2d57AA5c2EFFbdfdeD50E27B5bF, 905333896767)
    log Transfer(msg.sender, 0xBf6d95bCe8eD864e7117A0E17230834593Fd793D, 28800000000)
    log Transfer(msg.sender, 0x991f446FD0D84cADfA0ce7a1c4dE35DC02C4aCA2, 5901016516000)
    log Transfer(msg.sender, 0xE4F0547805A2a0A0d152017F39F3d433Dd41917A, 28800000000)
    log Transfer(msg.sender, 0x06751cca2c37eaCAF55B9A16b5DE771f0Ea3F58b, 13160575357400)
    log Transfer(msg.sender, 0x87dfea6B919589faF16bE6B5Ca01C239A5C6a38c, 81175486000)
    log Transfer(msg.sender, 0xDc92c0f15d96F0862f11734916E98d556982DF33, 499800592000)
    log Transfer(msg.sender, 0xEE9B89CEe4eD041C6385029EdAFb65f555bc0FE5, 843414000000)
    log Transfer(msg.sender, 0xC4Dc3a8390Dc0E98F27C4A46dfC9FAff387501f1, 4997525696000)
    log Transfer(msg.sender, 0x3FCA06242069aAe3B07ff8ebD69F54121C5005DE, 318000000)
    log Transfer(msg.sender, 0x2E1593c6765abe403D967205Bf1714249D312093, 1546258000000)
    log Transfer(msg.sender, 0x9FA6795267F0797cE36Fa554df0569B023B42dE5, 328041979000)
    log Transfer(msg.sender, 0xeC6D3CdDa02772630556fa198b83Fe331b8A42B0, 40452000000)
    log Transfer(msg.sender, 0x6346BA47665092855c879428aef512C63d249351, 319963500000)
    log Transfer(msg.sender, 0x95abD59345950cc55a0dE5c7B350ACA684FC1251, 14342237373790)
    log Transfer(msg.sender, 0x7334e3279b05c99dFFb815dF9450A04310Dd3fFB, 2838165192401)
    log Transfer(msg.sender, 0x57Bc3c5fE6dFF76bAE4Ab2c124F64D0Cc8a23F72, 99999000)
    log Transfer(msg.sender, 0x07283E73A2032d41fdEa3886DC8C2CA27e307c25, 4257197982000)
    log Transfer(msg.sender, 0xd54F3b57e9D800f191c66a603ED90448a652bA6d, 497437970000)
    log Transfer(msg.sender, 0x53273cb812c458B26b7EAA67331Fba346f70Ce6B, 115339844447071)

@view
@external
def balanceOf(_owner: address) -> uint256:
    """
    @notice Getter to check the current balance of an address
    @param _owner Address to query the balance of
    @return Token balance
    """
    return self.balances[_owner]


@view
@external
def allowance(_owner : address, _spender : address) -> uint256:
    """
    @notice Getter to check the amount of tokens that an owner allowed to a spender
    @param _owner The address which owns the funds
    @param _spender The address which will spend the funds
    @return The amount of tokens still available for the spender
    """
    return self.allowances[_owner][_spender]


@external
def approve(_spender : address, _value : uint256) -> bool:
    """
    @notice Approve an address to spend the specified amount of tokens on behalf of msg.sender
    @dev Beware that changing an allowance with this method brings the risk that someone may use both the old
         and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
         race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
         https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    @param _spender The address which will spend the funds.
    @param _value The amount of tokens to be spent.
    @return Success boolean
    """
    self.allowances[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True


@internal
def _transfer(_from: address, _to: address, _value: uint256):
    """
    @dev Internal shared logic for transfer and transferFrom
    """
    assert self.balances[_from] >= _value, "Insufficient balance"
    self.balances[_from] -= _value
    self.balances[_to] += _value
    log Transfer(_from, _to, _value)


@external
def transfer(_to : address, _value : uint256) -> bool:
    """
    @notice Transfer tokens to a specified address
    @dev Vyper does not allow underflows, so attempting to transfer more
         tokens than an account has will revert
    @param _to The address to transfer to
    @param _value The amount to be transferred
    @return Success boolean
    """
    self._transfer(msg.sender, _to, _value)
    return True


@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    """
    @notice Transfer tokens from one address to another
    @dev Vyper does not allow underflows, so attempting to transfer more
         tokens than an account has will revert
    @param _from The address which you want to send tokens from
    @param _to The address which you want to transfer to
    @param _value The amount of tokens to be transferred
    @return Success boolean
    """
    assert self.allowances[_from][msg.sender] >= _value, "Insufficient allowance"
    self.allowances[_from][msg.sender] -= _value
    self._transfer(_from, _to, _value)
    return True