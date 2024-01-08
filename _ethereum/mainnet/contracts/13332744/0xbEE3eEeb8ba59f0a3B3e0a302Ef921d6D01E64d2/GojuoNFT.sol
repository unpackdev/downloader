// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title GojuoNFT
 * GojuoNFT - a smart contract for Gojuon non-fungible token.
 */
contract GojuoNFT is ERC721Tradable {
    mapping (uint256 => string) private _tokenMidContents;
    mapping (uint256 => bytes32) private _tokenMidContentHashes;
    string[] private _tokenKanaWords = [ 
        "a","i","u","e","o",
        "ka","ki","ku","ke","ko",
        "sa","shi","su","se","so",
        "ta","chi","tsu","te","to",
        "na","ni","nu","ne","no",
        "ha","hi","fu","he","ho",
        "ma","mi","mu","me","mo",
        "ya","yu","yo",
        "ra","ri","ru","re","ro",
        "wa","wo","n"
    ];
    
    string[] private _tokenKanjiWords0 = [
        "sun","moon","fire","water","wood","gold"
    ];

    string[] private _tokenKanjiWords1 = [
        "soil","peak","ice","air","circle","wide"
    ];

    constructor(address _proxyRegistryAddress)
        ERC721Tradable("GojuoNFT", "GOJU", _proxyRegistryAddress)
    {
        _tokenMidContentHashes[0] = 0x9650ce19ad7b524d1ffd3899fa3241ffc06942b5ac71fe868ae311bc89473490;
        _tokenMidContentHashes[1] = 0xb336ae9b38480edf2d0a1cf9479525ba34f3d3c513df98db6c91bcc9a489699d;
        _tokenMidContentHashes[2] = 0x6a55639f64b2db3da80a9f9e78a85e3e180411e20798a5a41f02199de10bcb2a;
        _tokenMidContentHashes[3] = 0x52b57e6365c8eb2f01e23bdad945721d3f5b51f511d1c9a10d2406842745cefb;
        _tokenMidContentHashes[4] = 0x5c7e4aed1c393c6e2543d5e321b115283667559e88f87fd823eea989bca9505f;
        _tokenMidContentHashes[5] = 0xa67e12cea8b94ea6344ffcea8f5569c2e5af352c2d706865f2ef9d0202f9b9c9;
        _tokenMidContentHashes[6] = 0x0f3b966b558d6b842ece867764f0355efaba4bb235be071fcc45adf574948999;
        _tokenMidContentHashes[7] = 0x5f2b7678e28a0a2267b902d39de93ada3019312249e686b05f220da750e300f2;
        _tokenMidContentHashes[8] = 0x82f5b3fe5dc7a2853fde5bc22f0014b90cca2ef03e3091cd6b1d9d6677c3d12a;
        _tokenMidContentHashes[9] = 0x566e04f321c403572ff50d97d2848acacb8b1eb517a59e189fa819ce45e2a041;
        _tokenMidContentHashes[10] = 0x552b87264635fac094e7068e10db5a63e62b5cd67f52d08745b1a8427328a204;
        _tokenMidContentHashes[11] = 0x81af94ad9a621120f9bf5478dba19b4e9245f5a3830c07f3d08da88fb44f6061;
        _tokenMidContentHashes[12] = 0x132161ac353e852105ebb6e8002b92a944c683e56dc386b9c4acd34e3d99fb40;
        _tokenMidContentHashes[13] = 0x6ce7f3a19ba15a3d8cc87d271879c4473c2073ed74ebae47bccdae8e5a19ff72;
        _tokenMidContentHashes[14] = 0x7560fe13342bcac3347bad171cb2f54cc86d1eb23548a2f0fbd02ba967584892;
        _tokenMidContentHashes[15] = 0x8da33fc424ba7094d95231cc535a3d664f0f24dade53fe543a4d0fd309b4e465;
        _tokenMidContentHashes[16] = 0xc5858ec3f47fa778f651736e98adf57662d0e65b1bfd75d4265891eca1455786;
        _tokenMidContentHashes[17] = 0x6589ce1462d029685d0090469ee11713383573a7ac3b6d9d92ccaec0c6315355;
        _tokenMidContentHashes[18] = 0x6dc6ceef073da7909daa9adb73ba8055c41dfee721b147358564a04a20039593;
        _tokenMidContentHashes[19] = 0xc82ce6b609c7eb34dc2ddaed8ad996b60b7e4196a85b26a8370bb3c11279d5d7;
        _tokenMidContentHashes[20] = 0xde568d7dee5bd77594d7f2a375c6b76fd953d67d9a5613cfccca0e992f792242;
        _tokenMidContentHashes[21] = 0x90a6b28ea887fc24fd7e6a5957cbfe9f43125a4552e439e6becea0963d6f1cfa;
        _tokenMidContentHashes[22] = 0xc5b64e0440bce22084dc1d3f415c54a1b3c3d4555a888d40d4d9f1f256e20bd0;
        _tokenMidContentHashes[23] = 0xf89a002603020bd27500e1248ab15875c314970ab26f546937ec86dc23e0e955;
        _tokenMidContentHashes[24] = 0x1dffb249c59950b3ad516160a147653cb575d4bf1f2861b17d75471f4998d026;
        _tokenMidContentHashes[25] = 0xb664fc171e3cec988707352c6e8f1dbea0a507e8e7abaf4903108e6c0bb056e1;
        _tokenMidContentHashes[26] = 0xe2c74811d75bd8889876a15582173f95ef3d7ab6b2bd90be27cad20e6fb62d45;
        _tokenMidContentHashes[27] = 0x386f91bddc8a75058f31f5ea1030df6e2735ca6ff487e0975b243bf1fa837315;
        _tokenMidContentHashes[28] = 0x9f725f09744893b23f7479d4046a3e7d7e8c3a0dbcaeb6172c413d23e4cd0a4e;
        _tokenMidContentHashes[29] = 0x7eb079f6515ed8ccceca6b1abae4b30be5321f7d6015b816141934f6729d01c7;
        _tokenMidContentHashes[30] = 0x753073fe3bd8a310fc4948279f17fcf3379f60bef3f5b80603a8f52912d60c9e;
        _tokenMidContentHashes[31] = 0x118904718aefaf99e5880fe713081b61f5ee739b320f0a677330367f187dd18d;
        _tokenMidContentHashes[32] = 0x8cb587780070c627a24c9a924d8b81439f1c6e6e24e64b253c6a37cda96b3715;
        _tokenMidContentHashes[33] = 0x2bfe3db5aa42f27ea684e71f8f17a17537d0738f89d01dd8030bd5c2e121a29e;
        _tokenMidContentHashes[34] = 0x90017268aec14258357a42025a02cf33a688a80afd463ad2e3f0d60eb8a7929e;
        _tokenMidContentHashes[35] = 0x2f22b3eb1ec9685cdfbe86c0887b1e568b381ba852529127c7e074b8da527928;
        _tokenMidContentHashes[36] = 0x9f762612b235b0f023eb83417a6b322a9d11481a1378af160880c600e465ff53;
        _tokenMidContentHashes[37] = 0x263d752785c31090997652b1da672a721bc5467f66c3e5f457e594f1e2b81dc3;
        _tokenMidContentHashes[38] = 0x4ca2673e4e665d4a988b7fe686a63afec8d6d1ba14fe562e2d7d308bb20ca29b;
        _tokenMidContentHashes[39] = 0xa5e877090f83bc44e12d8ca6f96117fa57c612f2f26979d3ad1884584abe49d1;
        _tokenMidContentHashes[40] = 0xee5ad687929e92f08763e30c4ec930e126434fc67514f77c44e40f48338f2603;
        _tokenMidContentHashes[41] = 0xd0953a5a55067e29e3acd05327368bc9196fe2e19c1502b9fc4d6543a1a1c29e;
        _tokenMidContentHashes[42] = 0xd701952d7104bd11f10610ec9623665887ce70179a0df1997f9449c93f6e3cd2;
        _tokenMidContentHashes[43] = 0xa8070397febd15dc0099d607821d9f2763a668b01d0fbdea1c34a9c4ec46df6f;
        _tokenMidContentHashes[44] = 0xb8824b8e73ed06b8513ebf892c4e053705089d1cbd92219ce4cd60c48afb2e87;
        _tokenMidContentHashes[45] = 0x437a31d92937be2e5fadae6d138395c4ab37046b987d1b1794e754796659fb2e;
        _tokenMidContentHashes[46] = 0x0199050f9161a920c8731bffa6262713d54a2d86c46250931123966e46e71526;
        _tokenMidContentHashes[47] = 0x9939546e73069bd028560ce205acd1c947266440a7c5dffbd059f2d5ff83208f;
        _tokenMidContentHashes[48] = 0x861681e9b5f8b7cc4b411dadb362b77784487a1c086975c5cb61c2ae8b2bcb1c;
        _tokenMidContentHashes[49] = 0x4f232cf5d81a4489c907cf0c62e034b22843c7b4e2ab8197b307ae58af09406e;
        _tokenMidContentHashes[50] = 0xe5fc98b909f000f55ac1c484e4b8a687d908812e3a884a6355ff4e5ec8a52796;
        _tokenMidContentHashes[51] = 0x9db7e5fdf4bf71de8d4bda622bb48fb67830ed5801f90c79e71fcceb17ba0bf1;
        _tokenMidContentHashes[52] = 0x57c29dc3d94ea0ee8450f5d503fb8805428a60e5f38eaa6d87a916ae568bd391;
        _tokenMidContentHashes[53] = 0x31a6dd4d2814ad671c5c2e1f7e7dfce0e5969c0de8bbfb3670eda5a58884b86c;
        _tokenMidContentHashes[54] = 0x46d0f4055726b4933084e6b0397581dd82888a6c0c2958b091fe8bcee209e21e;
        _tokenMidContentHashes[55] = 0x89a1db70123a24ddef0dd39fedd88d1aed12b25156c97520c22b8c406c2e189d;
        _tokenMidContentHashes[56] = 0x1f8f137ca903f46c790cf7e247493da95c9fa093836bdb87aed16267c85bd633;
        _tokenMidContentHashes[57] = 0x2ce299f73559ec6006ff778cbe572d3f6be7dddf14d88eba94bde6274b3120f3;
        _tokenMidContentHashes[58] = 0x783dafe3bc34bbfb49d9ee9b3685b285f9fb456b31a2c911f1121341a995f20b;
        _tokenMidContentHashes[59] = 0x260f095a91d0be3495f145b22e8bc0ceb9e722238bbed4989c8566913f712dd4;
        _tokenMidContentHashes[60] = 0x9b9fd19745f46ecaf0f3ba3eb7d049ba7f6e6ef0a5cd46fb3888f69d5cb63f1a;
        _tokenMidContentHashes[61] = 0xc42e695f4ee6c236380e2f8a56203cb48b797fac8bb675b1d2632e1da00a6e6b;
        _tokenMidContentHashes[62] = 0xac64d3b3d7a704ab7b59003e753b19ec8f0eeec02ce8de0e7f7ce8c6c04911a5;
        _tokenMidContentHashes[63] = 0xb6947eae3441b9496436e0605fdcfd89df4ca478a86e8b729d7b2e044a5fa91c;
        _tokenMidContentHashes[64] = 0x350e62beb83c85a82a40a4755e6de7b48d3c3f107ab19a077aa5a7bf08d96780;
        _tokenMidContentHashes[65] = 0x230f8db27086b7f0ed5fe67cb6e801f7183c2a5bb2e8c332dd8fabb627e28091;
        _tokenMidContentHashes[66] = 0x471ad3d31fa25598f86d8a9456e61645ca5e1cbc76251d05a789695a9f4970a7;
        _tokenMidContentHashes[67] = 0xd29a77b63d2bf389b2ed3103425acb19d94eb376016180048482b13053fe8de4;
        _tokenMidContentHashes[68] = 0xcaf1d85dddc3b9a36304b7f12a78cbc4e28fc311ea7b52ee0906dc0808447662;
        _tokenMidContentHashes[69] = 0x10fa630ef45e59e10840723986542ed6ca25ebe0054537a20ce3a06180dfa6f8;
        _tokenMidContentHashes[70] = 0x97dfef88681bccd41cab451c565916a309e307011944f73a2993a0384fa10893;
        _tokenMidContentHashes[71] = 0xc6d77634cd8f93f3baa1d3a8aa911eead879e66bb3879079ae4a1ce24bf855d4;
        _tokenMidContentHashes[72] = 0xb1b30070212cba9640e1e77c821afd62904f5ddcb8ed41b4d238d89f5bbc6f2e;
        _tokenMidContentHashes[73] = 0xbf3fbc48d354ccdbe966ac4fce09f8e5ed0b68c4718f4ab7703b539ab0111517;
        _tokenMidContentHashes[74] = 0x2f1a310cb22dd990b116d9ede0267d55d3aeb110dc0f0b3e043b914dd748aed4;
        _tokenMidContentHashes[75] = 0x5b3bce99e6eedcc87a086ffc9bca480cff4075b6f593c5ff83a1b30782e4fe43;
        _tokenMidContentHashes[76] = 0xf1e46f2be1c113a80beb7d2e777859808b2e33e020d9ba60dd6ab3831d8e5b51;
        _tokenMidContentHashes[77] = 0x5ebf03cf01509e8631cf022aaae0b69c1a0c1c1798d02bf83af9fc27ad941ec6;
        _tokenMidContentHashes[78] = 0x3f91278012c5039c58f3971d7c2ef4b13c0fbf402cc28bbf91f3d6ed123f614f;
        _tokenMidContentHashes[79] = 0x1ea24c514540df5ad7e8484a232e7472e8bc66d6eae38c03f8b30fada02c28c7;
        _tokenMidContentHashes[80] = 0x5fac5003e25f6980de03da6b501ee4f460cf3bcda093f68eaa12dc806961e0f6;
        _tokenMidContentHashes[81] = 0x63ce9e3960a730a5f47c6320db8c4368f94e2ef6b7d64ff5e1944880864cd32e;
        _tokenMidContentHashes[82] = 0xfa2e7ec47ac7651ba741f518cb9af26bd016925e78428e38a1340f40f104a42b;
        _tokenMidContentHashes[83] = 0xa0f4161b0bcac7f93667b52ae9f5a8df504f70881801ace8203675d2445b5acd;
        _tokenMidContentHashes[84] = 0x5f3b81f5583d86526551ac861a96fb0e6d8ba001cfeb6278bb30d0f3b840323c;
        _tokenMidContentHashes[85] = 0x54eb601bfa70f5337be55e4355ffd4398e5b4cc6627cb6981e76cd06419ad6bc;
        _tokenMidContentHashes[86] = 0xfa3977e587bafc4f0f464628530146ff7c30863cf275b9d645a817b2d9d0d97e;
        _tokenMidContentHashes[87] = 0xa71211036e84dcf885ae4b9198a6c4e2e11bb33704ed52c69bd93cd28df37a70;
        _tokenMidContentHashes[88] = 0x0fe4bffa3040a687414476ab5b1a66d22b48ff9f407ef484c31335aac86ff0c0;
        _tokenMidContentHashes[89] = 0xfea3f2d066021563560c779021c0ddbe7152b55a65d5cc0f3b7d4ef8e7a95356;
        _tokenMidContentHashes[90] = 0xea7b325517c55f42b0c1b45cef656eecfda178de841aaeee22f3ca5b7ef8ac28;
        _tokenMidContentHashes[91] = 0x635a7455a706630a9f949f76f3c95aa2161de284b9b608e4d552552cc2f9f242;
        _tokenMidContentHashes[92] = 0xb64e3fec4e414b6b716714969401e0a3859d55c5702d1a19a493f0cfa4c1dabf;
        _tokenMidContentHashes[93] = 0x833df3bef30ab3893443a35133445b0b3e1d8000cf227bd09310d50a8b7c78ff;
        _tokenMidContentHashes[94] = 0x6ab91eb3a5b7986ee813380bef8590b228893cd2ae873086156fceda5aa32aa6;
        _tokenMidContentHashes[95] = 0xb5f059de37daa4c293b62512113abc5cff5568ce0b8e57a87f7f26cef2cae581;
        _tokenMidContentHashes[96] = 0x601de7bdc5507f3175b1ebff3e0757c50c2b63b4fd55033cf4c67d8da657da41;
        _tokenMidContentHashes[97] = 0x7a9dd784c4b171b65521f972bad33f8fbef3b35384c9ddb0b61cefa03e6bebed;
        _tokenMidContentHashes[98] = 0x4cff1425770ae1a616f41d79e640c213238899da86ea1a13ac46fac0b5c61c6f;
        _tokenMidContentHashes[99] = 0xe3242325f46764c383b8f11a9d70d4729f0fda57600b5285fd09d55de0dd0306;
        _tokenMidContentHashes[100] = 0x0bf1728c5265e34b120ea3516f6cf0762a9cf3034f52957aa2b896b547963d72;
        _tokenMidContentHashes[101] = 0x690de6045948cebf760a2b397d2709bfc6f23c871d7b055a97eac8fae8995462;
        _tokenMidContentHashes[102] = 0x5577f533d6c6ce544538e223a125a3d4471189cdfd362ed776a96016e874cf4b;
        _tokenMidContentHashes[103] = 0xceb8ff160b22e69bfd26a8a93c96568f57f1bcdc0527d0fe36633b8dad6b70e9;
    }

    function baseTokenURI() override public pure returns (string memory) {
        return "https://gojuonft.io/metadata/";
    }

    function getSuit(uint256 _tokenId) public pure returns (string memory) {
        require(_tokenId >= 0 && _tokenId < 2704, "Token ID invalid");
        uint256 suitNum = ( _tokenId / 13 ) % 4;
        string memory suit;
        if (suitNum == 0) {
            suit = "diamonds";
        } else if (suitNum == 1) {
            suit = "clubs";
        } else if (suitNum == 2) {
            suit = "hearts";
        } else if (suitNum == 3) {
            suit = "spades";
        }
        return suit;
    }

    function getRank(uint256 _tokenId) public pure returns (string memory) {
        require(_tokenId >= 0 && _tokenId < 2704, "Token ID invalid");
        uint256 rankNum = _tokenId % 13;
        string memory rank;
        if (rankNum == 0) {
            rank = "A";
        } else if (rankNum == 10) {
            rank = "J";
        } else if (rankNum == 11) {
            rank = "Q";
        } else if (rankNum == 12) {
            rank = "K";
        } else {
            rank = Strings.toString(rankNum + 1);
        }
        return rank;
    }

    function getWord(uint256 _tokenId) public view returns (string memory) {
        require(_tokenId >= 0 && _tokenId < 2704, "Token ID invalid");
        uint256 shifting_index;
        uint256 words_index;
        string memory prefix;
        if (_tokenId / 52 % 2 == 0) {
            shifting_index = _tokenId / 52 / 2;
            prefix = "hiragana-";
        } else {
            shifting_index = (_tokenId / 52 - 1) / 2;
            prefix = "katakana-";
        }
        
        if (_tokenId % 52 < shifting_index) {
            words_index = 52 + _tokenId % 52 - shifting_index;
        } else {
            words_index = _tokenId % 52 - shifting_index;
        }

        if (_tokenId / 52 % 2 == 0 && words_index > 45) {
            return _tokenKanjiWords0[words_index - 46];
        } else if (_tokenId / 52 % 2 == 1 && words_index > 45) {
            return _tokenKanjiWords1[words_index - 46];
        } else {
            return string(abi.encodePacked(prefix, _tokenKanaWords[words_index]));
        }
    }

    function getTopContent(string memory _suit) public pure returns (bytes memory) {
        string memory startPart;
        string memory suitPart1;
        string memory suitPart2;
        string memory suitPart3;
        string memory suitPart4;
        string memory endPart;
        startPart = " _____________________________\n|  ?                          |\n";
        endPart = "                        |\n";
        if ( (keccak256(abi.encodePacked(_suit))) == (keccak256(abi.encodePacked("diamonds"))) ) {
            suitPart1 = "|  /\\ ";
            suitPart2 = "| /  \\";
            suitPart3 = "| \\  /";
            suitPart4 = "|  \\/ ";
        } else if ( (keccak256(abi.encodePacked(_suit))) == (keccak256(abi.encodePacked("clubs"))) ) {
            suitPart1 = "|  () ";
            suitPart2 = "| ()()";
            suitPart3 = "|  /\\ ";
        } else if ( (keccak256(abi.encodePacked(_suit))) == (keccak256(abi.encodePacked("hearts"))) ) {
            suitPart1 = "| /\\/\\";
            suitPart2 = "| \\  /";
            suitPart3 = "|  \\/ ";
        } else if ( (keccak256(abi.encodePacked(_suit))) == (keccak256(abi.encodePacked("spades"))) ) {
            suitPart1 = "|  /\\ ";
            suitPart2 = "| /__\\";
            suitPart3 = "|  /\\ ";
        }
        if ( (keccak256(abi.encodePacked(_suit))) == (keccak256(abi.encodePacked("diamonds"))) ) {
            return abi.encodePacked(startPart, suitPart1, endPart, suitPart2, endPart, suitPart3, endPart, suitPart4, endPart);
        } else {
            return abi.encodePacked(startPart, suitPart1, endPart, suitPart2, endPart, suitPart3, endPart);
        }
    }

    function getMidContent(uint256 _tokenId) public view returns (bytes memory) {
        require(_tokenId >= 0 && _tokenId < 104, "Refer to token ID 0-103 for middle part of NFT content");
        return bytes(_tokenMidContents[_tokenId]);
    }

    function getBottomContent() public pure returns (bytes memory) {
        return bytes("|                             |\n|           = ? =             |\n|_____________________________|");
    }

    // function sliceBytes32To10(bytes32 input) public pure returns (bytes10 output) {
    //     assembly {
    //         output := input
    //     }
    // }

    function claim(address _to, uint256 _tokenId, string memory _tokenMidContent) public {
        require(_tokenId >= 0 && _tokenId < 2392, "Token ID invalid");
        if (_tokenId >= 0 && _tokenId < 104) {
            require(bytes(_tokenMidContent).length == 429, "Token Content Size invalid");
            require(_tokenMidContentHashes[_tokenId] == keccak256(abi.encodePacked(_tokenMidContent)), "Token Content invalid");
        } else {
            _tokenMidContent = "";
        }
        _safeMint(_to, _tokenId);
        _tokenMidContents[_tokenId] = _tokenMidContent;
    }

    function ownerClaim(address _to, uint256 _tokenId) public onlyOwner {
        require( _tokenId >= 2392 && _tokenId < 2704, "Token ID invalid");
        _safeMint(_to, _tokenId);
    }
}