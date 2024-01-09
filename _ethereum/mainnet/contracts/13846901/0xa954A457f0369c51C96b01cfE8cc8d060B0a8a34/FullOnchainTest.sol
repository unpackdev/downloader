// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Base64.sol";


contract OriginalOtakuCoin is ERC721Enumerable, Ownable {

    string[] private color1 = [
        "fff100","f9ec00","ece700","e1e200","d2dc00","c7d800","b7d200","aacd05","97c619","89c221","74bb2a","62b62f","44b035","23ac38","00a63c","00a23f","009d42","009a44","009a4b","009a53","009b5e","009b65","009c71","009c79","009d85","009d8e","009e99","009ea2","009fad","009fb5","00a0c1","00a0c9","00a0d4","00a0dc","00a0e7","009de6","0096df","0091db","008ad4","0084cf","007cc8","0076c3","006ebc","0068b7","005faf","0059aa","0050a3","00499e","004098","003894","102e8e","441d87","541b86","601986","6f1585","791285","860e84","8f0983","9b0283","a40082","b00082","b80081","c30080","cb0080","d5007f","dd007f","e4007e","e40079","e40074","e5006f","e50069","e50064","e5005d","e50058","e50051","e5004c","e60044","e6003e","e60037","e60031","e60029","e60023","e60019","e60012","e72c0f","e83e0c","ea5106","eb5d01","ed6d00","ee7700","f08600","f29100","f49d00","f6a800","f8b500","fabe00","fcca00","fed200","ffde00","ffffff"
    ];
    string[] private color2 = [
        "dfd000","d7cd00","cbc800","c2c400","b5bf00","acbb00","9eb600","93b200","83ad12","77a91a","64a322","549f27","399a2d","1a9630","009134","008e37","008a39","00883b","008742","008749","008852","008858","008862","00896a","008974","008a7c","008a85","008b8d","008b98","008b9f","008ca9","008cb0","008db9","008dc0","008dc9","008ac8","0084c3","007fbf","0079b9","0073b5","006caf","0067aa","005fa4","005aa0","00529a","004d95","004490","003e8b","003686","002f82","0c257d","3b1477","491176","540f76","600a75","6a0674","750173","7d0073","870072","8f0072","990071","a00070","aa0070","b10070","ba006f","c0006f","c6006e","c6006a","c70065","c70061","c7005b","c70057","c70050","c7004c","c70045","c70041","c7003a","c70034","c7002e","c70028","c70021","c7001b","c70013","c7000b","c82408","c93406","cb4501","cb5000","cd5e00","ce6700","d07400","d17d00","d38800","d49100","d69c00","d8a500","daaf00","dbb600","ddc000","dcdddd"
    ];
    string[] private color3 = [
        "cbbd00","c3ba00","b9b600","b0b300","a5ae00","9cab00","8fa600","85a200","769d0c","6b9a15","5a951d","4b9122","328d27","148a2b","00852f","008231","007f34","007d36","007c3c","007c42","007d4b","007d51","007d5a","007e61","007e6a","007e71","007f7a","007f81","00808b","008092","00809b","0081a1","0081aa","0081b0","0081b8","007fb8","0079b3","0075af","006eaa","006aa6","0063a1","005e9d","005797","005293","004a8d","004589","003d84","003780","002f7b","002978","081f73","350d6d","430a6d","4c076c","58026b","60006a","6b006a","720069","7c0068","830068","8c0067","930067","9b0066","a20066","aa0066","af0066","b50064","b50061","b5005c","b50058","b50053","b5004f","b50049","b50044","b5003e","b5003a","b50033","b5002e","b50028","b50022","b6001b","b60016","b6000d","b60005","b71f03","b72e00","b93d00","b94800","bb5400","bc5d00","bd6900","be7100","c07c00","c18400","c38e00","c49600","c69f00","c7a600","c8af00","c9c9ca"
    ];
    string[] private color4 = [
        "a09600","9a9300","929000","8b8d00","818a00","7b8700","708400","688100","5c7d00","527a05","44760f","377414","21701a","006e1d","006b21","006823","006626","006428","00642d","006432","00643a","00643f","006446","00654c","006554","00655a","006662","006668","00666f","006675","00677c","006782","006789","00678e","006794","006594","006090","005d8d","005889","005486","004e81","004a7e","00447a","003f76","003972","00346e","002d6a","002767","002063","001960","000f5c","280057","330057","3b0056","450055","4c0055","550054","5b0053","620052","680052","700051","750051","7c0050","810050","880050","8c004f","91004e","91004b","910047","910044","91003f","91003b","900036","900032","90002d","900029","900023","90001f","900018","900013","91000c","910006","910000","910000","911100","921f00","932d00","933500","944000","954700","965100","975800","986000","996700","9a6f00","9b7600","9c7d00","9d8300","9e8a00","9f9fa0"
    ];
    string[] private color5 = [
        "8a8000","857e00","7d7c00","777900","6f7600","697400","607100","586f00","4d6b00","456900","386605","2c630b","176111","005e14","005c18","005a1b","00581d","00561f","005624","005629","005630","005634","00573b","005741","005748","00574d","005754","005859","005860","005865","00586b","005870","005976","00597b","005980","005780","00527d","004f7a","004b77","004774","004270","003e6d","003869","003466","002e62","002a60","00235c","001e59","001655","000f53","000450","20004b","2a004a","32004a","3b0049","410048","490047","4e0047","550046","5a0046","610045","650044","6b0044","700044","760043","7a0043","7e0042","7e003f","7e003b","7d0038","7d0034","7d0030","7d002b","7d0028","7d0023","7d001f","7d001a","7d0015","7d000f","7d0008","7d0001","7d0000","7d0000","7d0000","7e0600","7e1500","7f2300","7f2b00","803500","813b00","824400","824a00","835200","845800","855f00","866400","876b00","877000","887600","898989"
    ];

    function getColor(uint256 tokenId, string[] memory sourceArray) public pure returns (string memory) {
        string memory output = sourceArray[tokenId - 1];
        return output;
    }
    
    function mint(address _to, uint256 _tokenId) public onlyOwner {
        _mint(_to, _tokenId);
    }

    function bulkMint(address[] memory _toList, uint256[] memory _tokenIdList) public onlyOwner {
        require(_toList.length == _tokenIdList.length, "input length must be same");
        for (uint256 i = 0; i < _tokenIdList.length; i++) {
            _mint(_toList[i], _tokenIdList[i]);
        }
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[23] memory parts;

        parts[0] = '<svg id="layer_1" data-name="layer 1" xmlns="http://www.w3.org/2000/svg" viewBox="-38 -60 642.93 630.24"><defs><style>.cls-6{fill:#';
        parts[1] = getColor(tokenId, color1);
        parts[2] = ';}.cls-4{fill:#';
        parts[3] = getColor(tokenId, color2);
        parts[4] = ';}.cls-1{fill:#';
        parts[5] = getColor(tokenId, color3);
        parts[6] = ';}.cls-5{fill:#';
        parts[7] = getColor(tokenId, color4);
        parts[8] = ';}.cls-3{fill:#';
        parts[9] = getColor(tokenId, color5);
        parts[10] = ';}.cls-2{fill:#3d3938;}</style></defs>';
        parts[11] = '<polygon class="cls-1" points="510.24 113.39 510.24 56.69 453.54 56.69 453.54 0 340.16 0 170.08 0 113.39 0 113.39 56.69 56.69 56.69 56.69 113.39 0 113.39 0 396.85 56.69 396.85 56.69 453.54 113.39 453.54 113.39 510.24 170.08 510.24 340.16 510.24 453.54 510.24 453.54 453.54 510.24 453.54 510.24 396.85 566.93 396.85 566.93 340.16 566.93 170.08 566.93 113.39 510.24 113.39"/>';
        parts[12] = '<polygon class="cls-2" points="510.24 113.39 510.24 56.69 453.54 56.69 453.54 0 113.39 0 113.39 56.69 113.39 113.39 113.39 170.08 453.54 170.08 453.54 340.16 113.39 340.16 113.39 396.85 113.39 453.54 113.39 510.24 453.54 510.24 453.54 453.54 510.24 453.54 510.24 396.85 566.93 396.85 566.93 340.16 566.93 170.08 566.93 113.39 510.24 113.39"/>';
        parts[13] = '<polygon class="cls-3" points="113.39 170.08 113.39 113.39 170.08 113.39 170.08 0 113.39 0 113.39 56.69 56.69 56.69 56.69 113.39 0 113.39 0 396.85 56.69 396.85 56.69 453.54 113.39 453.54 113.39 510.24 170.08 510.24 170.08 396.85 113.39 396.85 113.39 340.16 56.69 340.16 56.69 170.08 113.39 170.08"/>';
        parts[14] = '<polygon class="cls-4" points="396.85 113.39 396.85 56.69 340.16 56.69 340.16 0 170.08 0 170.08 56.69 283.46 56.69 283.46 113.39 340.16 113.39 340.16 170.08 396.85 170.08 396.85 340.16 340.16 340.16 340.16 396.85 283.46 396.85 283.46 453.54 170.08 453.54 170.08 510.24 340.16 510.24 340.16 453.54 396.85 453.54 396.85 396.85 453.54 396.85 453.54 340.16 453.54 170.08 453.54 113.39 396.85 113.39"/>';
        parts[15] = '<rect class="cls-5" x="420.81" y="392.2" width="170.08" height="56.69" transform="translate(789.05 -250.73) rotate(90)"/>';
        parts[16] = '<rect class="cls-5" x="420.81" y="278.81" width="56.69" height="56.69" transform="translate(760.97 448.89) rotate(-180)"/>';
        parts[17] = '<rect class="cls-5" x="420.81" y="505.58" width="56.69" height="56.69" transform="translate(760.97 902.44) rotate(-180)"/>';
        parts[18] = '<rect class="cls-6" x="137.35" y="392.2" width="170.08" height="56.69" transform="translate(505.58 32.73) rotate(90)"/>';
        parts[19] = '<rect class="cls-6" x="113.39" y="113.39" width="56.69" height="56.69"/><rect class="cls-6" x="113.39" y="340.16" width="56.69" height="56.69"/>';
        parts[20] = '<rect class="cls-6" x="170.08" y="396.85" width="113.39" height="56.69"/>';
        parts[21] = '<rect class="cls-6" x="170.08" y="56.69" width="113.39" height="56.69"/>';
        parts[22] = '<polygon class="cls-1" points="340.16 170.08 283.46 170.08 283.46 113.39 170.08 113.39 170.08 170.08 113.39 170.08 113.39 340.16 170.08 340.16 170.08 396.85 283.46 396.85 283.46 340.16 340.16 340.16 340.16 170.08"/></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        output = string(abi.encodePacked(output, parts[17], parts[18], parts[19], parts[20], parts[21], parts[22]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "#', toString(tokenId),' Original Otaku Coin', '", "description": "The Otaku Coin Association has created a limited quantity of 100 fully on-chain Original Otaku Coin NFTs as a symbol of our mission to spread Japanese anime culture to the world. We hope that these Original Otaku Coin NFTs will be owned and traded by anime fans and communities all over the world, and that the excellence of anime culture will spread and develop more globally.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }
    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    uint256 _tmpNumber = value;
    bytes memory buffer = new bytes(3);

        if (_tmpNumber == 0) {
            return "0";
        }
        uint256 temp = _tmpNumber;
        uint256 digits = 0;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        buffer[0] = "0";
        buffer[1] = "0";
        buffer[2] = "0";
        uint i = 0;
        while (_tmpNumber != 0) {
            buffer[2 - i] = bytes1(uint8(48 + uint256(_tmpNumber % 10)));
            _tmpNumber /= 10;
            i += 1;
        }
        return string(buffer);
    }

    constructor() ERC721("Original Otaku Coin", "XOC") {}
}