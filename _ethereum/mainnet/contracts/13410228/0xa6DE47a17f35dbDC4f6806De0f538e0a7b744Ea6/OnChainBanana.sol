// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//       *******                    **                **
//      **/////**                  /**               //
//     **     //** *******   ***** /**       ******   ** *******
//    /**      /**//**///** **///**/******  //////** /**//**///**
//    /**      /** /**  /**/**  // /**///**  ******* /** /**  /**
//    //**     **  /**  /**/**   **/**  /** **////** /** /**  /**
//     //*******   ***  /**//***** /**  /**//********/** ***  /**
//      ///////   ///   //  /////  //   //  //////// // ///   //
//                ******
//               /*////**
//               /*   /**   ******   *******   ******   *******   ******
//               /******   //////** //**///** //////** //**///** //////**
//               /*//// **  *******  /**  /**  *******  /**  /**  *******
//               /*    /** **////**  /**  /** **////**  /**  /** **////**
//               /******* //******** ***  /**//******** ***  /**//********
//               ///////   //////// ///   //  //////// ///   //  ////////

// 3,333 organic generative banana made fully on chain.
// Fruit comes with exciting varieties of traits and rarities,
// including age, sugar spots and colors.

// Our bananas are drawn using generative method in real time.
// Not knowing what the end result will be, it will certainly bring surprised to your table.
// Life is fun and healthy with OnChainBananas!


import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

import "./Spots.sol";
import "./Util.sol";

contract OnChainBanana is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;
    uint256 private constant maxTokensPerTransaction = 10;
    uint256 private tokenPrice = 0.05 ether;
    uint256 private constant tokenMaxSupply = 3333;

    address private _a = 0x919036152224102F223641057770F8895a12c46C;
    address private _b = 0xF9466BE8B026ee4Fe22B69e69D84e95f515320e6;
    address private _c = 0x000001947A9A22D0C77097FF1942E7Cf9385C1Ba;

    mapping(uint256 => uint256) private _seeds;
    mapping(uint256 => uint256) private _ages;

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function getPrice() public view returns (uint256) {
        return tokenPrice;
    }

    function getSeed(uint256 tokenId) public view returns (uint256) {
        require(
            tokenId < _tokenIdCounter.current(),
            "call to a non-exisitent token"
        );
        return _seeds[tokenId];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _getSticker(uint256 sticker_type)
        private
        pure
        returns (string memory)
    {
        string memory text = [
            "HODL!",
            "Banana",
            "MOON",
            "DOGE",
            "DEGEN",
            "Zombie",
            "ELON",
            "A P E"
        ][sticker_type / 8];
        string memory color = [
            "#C47",
            "#E73",
            "#457",
            "#1A4",
            "#444",
            "#39A",
            "#112",
            "#538"
        ][sticker_type % 8];
        return _getSticker_sub(color, text);
    }

    function _getSticker_sub(string memory color, string memory text)
        private
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<g transform="translate(-10 5)"><filter id="f"><feDropShadow dx="0" dy="2" stdDeviation="0" flood-color="#330" flood-opacity="0.3"/></filter><path filter="url(#f)" d="m317 551c51 0 92 38 92 73 0 43-35 40-87 40-51 0-93 2-93-42  0-35 36-71 88-71z" fill="',
                    color,
                    '" transform="matrix(.72 -.45 .45 .72 -207 161)" stroke="#EEE" stroke-width="8"/>',
                    '<path id="c" fill="transparent" d="m235 375s29-32 47-45c17-12 59-29 59-29" transform="translate(20 135)" /><text fill="#EEE" style="font-size:30px;font-weight:bold;"><textPath startOffset="50%" text-anchor="middle" xlink:href="#c">',
                    text,
                    "</textPath></text>",
                    "</g>"
                )
            );
    }

    function _easeout(uint256 x) private pure returns (uint256) {
        uint256 y = (100 - x);
        return 100 - (y * y * y) / 10000;
    }

    function _getColor(uint256 age) private pure returns (string memory) {
        string memory red = Util.toStr((_easeout(age) * 165) / 100 + 90);
        string memory green = Util.toStr(210 - ((_easeout(age) * 30) / 100));
        return string(abi.encodePacked("rgb(", red, ",", green, ",20)"));
    }

    function _getRainbowGradient() private pure returns (string memory) {
        return
            '<linearGradient id="r" x2="1" y2="1"><stop offset=".2" stop-color="#0FF"/><stop offset=".5" stop-color="#FF0"/><stop offset="1" stop-color="#F0F"/></linearGradient>';
    }

    function _getRainbowGradient2() private pure returns (string memory) {
        return
            '<linearGradient id="r" x2="1" y2="1"><stop offset=".2" stop-color="#FF0"/><stop offset=".5" stop-color="#0F0"/><stop offset=".8" stop-color="#0FF"/></linearGradient>';
    }

    function _getGrowthGradient(uint256 age)
        private
        pure
        returns (string memory)
    {
        if (age < 15 || age > 50) return "";
        uint256 rate = 80 - (age - 15) * 2;
        return
            string(
                abi.encodePacked(
                    '<linearGradient id="g" x2="1" y2="1"><stop offset="',
                    Util.toFloatStr(rate),
                    '" stop-color="',
                    _getColor(15),
                    '"/><stop offset="',
                    Util.toFloatStr(rate.add(15)),
                    '" stop-color="',
                    _getColor(50),
                    '"/></linearGradient>'
                )
            );
    }

    function _getPairBanana(uint256 pair) private pure returns (string memory) {
        return
            pair < 1
                ? '<g id="bn"><g>'
                : string(
                    abi.encodePacked(
                        '<g id="bn">',
                        pair > 1
                            ? '<use xlink:href="#b" transform="scale(.8 .8) rotate(-16 0 0) translate(29 21)" />'
                            : "",
                        '<use xlink:href="#b" transform="scale(.9 .9) rotate(-11 0 0) translate(-18 11)" /><g transform="translate(-50 0)">'
                    )
                );
    }

    function _getBananaBody(
        uint256 age,
        string memory sticker,
        string memory spots,
        uint256 pair,
        uint256 special
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _getGrowthGradient(age),
                    special == 4 ? _getRainbowGradient() : special == 3
                        ? _getRainbowGradient2()
                        : "",
                    _getPairBanana(pair),
                    '<g id="b"><path id="bb" d="m103.5 28.5-39 8v31l33 17 14 50-20 29s-74.519 188.481 132 395c70 70 180 145 401 145l71-40 27-20 7-30-7-29s-188.429-69.985-255-105c-154-81-276-336-276-336l-37-24-11-71z" transform="translate(16 31)" /><use xlink:href="#bb" fill="',
                    special == 4 || special == 3 ? "url(#r)" : special == 2
                        ? "#FF0"
                        : special == 1
                        ? "#6F0"
                        : age >= 15 && age <= 50
                        ? "url(#g)"
                        : _getColor(age),
                    '" stroke="#330" stroke-width="16" paint-order="stroke" /><path d="m105.5 46.5 40 20 11 71-43 15-14-50-33-17v-31z" fill="url(#a)" transform="translate(14 13)"/><path d="m138 99 22-19 11 71-21 15-18 23s-34 251 228 411c68.067 41.568 345 61 345 61l6.943 33.723-70.943 40.277c-221 0-331-75-401-145-206.519-206.519-132-395-132-395l20-29-14-50-33-17z" fill="url(#s)" /><use xlink:href="#bb" fill="url(#m)" />',
                    spots,
                    '<path d="m119.5 42.5-26 20-8 25 7 34 27-20 7-30z" fill="#552" transform="translate(620 575)"/></g>',
                    sticker,
                    "</g></g>"
                )
            );
    }

    function _svgEnvelop(string memory content, uint256 duration)
        private
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<svg fill-rule="evenodd" height="800" width="800" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" ><animateTransform id="e" xlink:href="#bn" attributeName="transform" type="rotate" values="0.5;2;4;-5;3;-2;1;-1;.5;-.5;.2;-.2" dur="1s" begin="',
                    Util.toStr(duration / 2 + 1),
                    "s;e.end+",
                    Util.toStr(duration),
                    's" /><pattern id="s" width="8" height="8" patternUnits="userSpaceOnUse" patternTransform="rotate(130) translate(3 3)"><line x1="0" y="0" x2="0" y2="7" stroke="#543" stroke-width="2" /></pattern><pattern id="m" width="8" height="8" patternUnits="userSpaceOnUse" patternTransform="rotate(130)"><line x1="0" y="0" x2="0" y2="4" stroke="#FFF" stroke-width="2" opacity=".5" /></pattern><linearGradient id="a" gradientTransform="matrix(49 92 -92 49 96 75)" gradientUnits="userSpaceOnUse" x2="1"><stop offset="0" stop-color="#ce0"/><stop offset=".8" stop-color="#ce0" stop-opacity="0"/></linearGradient>',
                    content,
                    "</svg>"
                )
            );
    }

    function getAge(uint256 tokenId) public view returns (uint256) {
        return (block.timestamp - _ages[tokenId]).div(1 days);
    }

    function aging(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "You have no rights");
        uint256 seed = _seeds[tokenId];
        uint256 age = seed % 100;
        age = age + getAge(tokenId);
        if (age >= 99) {
            age = 99;
        }
        _ages[tokenId] = block.timestamp;
        _seeds[tokenId] = (_seeds[tokenId].sub(seed % 100)).add(age);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(
            tokenId < _tokenIdCounter.current(),
            "call to a non-exisitent token"
        );

        uint256 seed = _seeds[tokenId];
        uint256[6] memory traits;
        traits[0] = seed % 100;
        traits[1] = (seed /= 1000) % 1000;
        traits[1] = traits[1] > 700 ? (traits[1] % 64) : 100;
        traits[2] = (seed /= 1000) % 1000;
        traits[2] = traits[2] > 600 ? (traits[2] % 16) : 100;
        traits[3] = (seed /= 1000) % 1000;
        traits[3] = traits[3] > 950 ? (traits[3] > 980 ? 2 : 1) : 0;
        traits[4] = (seed /= 1000) % 1000;
        traits[4] = traits[4] > 950
            ? traits[4] > 980
                ? traits[4] > 990 ? traits[4] > 996 ? 4 : 3 : 2
                : 1
            : 0;
        traits[5] = ((seed /= 1000) % 100);
        traits[5] = traits[5] < 4 ? traits[5] + 1 : (traits[5] % 4) + 7;

        string memory output = _getBananaBody(
            traits[0],
            traits[1] < 100 ? _getSticker(traits[1]) : "",
            traits[2] < 100 ? SpotsUtil._getSpots(traits[2]) : "",
            traits[3],
            traits[0] > 50 ? traits[4] : 0
        );

        output = _svgEnvelop(output, traits[5]);

        string memory attributes = string(
            abi.encodePacked(
                '[{ "trait_type": "Age", "value": "',
                Util.toStr(traits[0]),
                '"},{ "trait_type": "Sticker", "value": "',
                traits[1] == 100 ? "none" : Util.toStr(traits[1]),
                '"},{ "trait_type": "Spots", "value": "',
                traits[2] == 100 ? "none" : Util.toStr(traits[2]),
                '"},{ "trait_type": "Cluster", "value": "',
                Util.toStr(traits[3] + 1),
                '"},{ "trait_type": "Special", "value": "',
                traits[4] == 0 ? "none" : Util.toStr(traits[4]),
                '"}]'
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "OnChain Banana #',
                        Util.toStr(tokenId),
                        '", "description": "Our bananas are drawn using generative method in real time. Not knowing what the end result will be, it will certainly bring surprised to your table. Life is fun and healthy with OnChainBananas!","attributes":',
                        attributes,
                        ', "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );

        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 split = balance.div(3);
        require(payable(_a).send(split), "Failed to transfer funds to A");
        require(payable(_b).send(split), "Failed to transfer funds to B");
        require(payable(_c).send(split), "Failed to transfer funds to C");
    }

    function buyBanana(uint256 tokensNumber) public payable {
        require(tokensNumber > 0, "the number is too small");
        require(
            tokensNumber <= maxTokensPerTransaction,
            "number of tokens exceeds the range"
        );
        require(
            _tokenIdCounter.current().add(tokensNumber) <= tokenMaxSupply,
            "number of tokens exceeds the range"
        );
        require(
            tokenPrice.mul(tokensNumber) <= msg.value,
            "The amount is not enough"
        );

        if (msg.value > tokenPrice.mul(tokensNumber)) {
            uint256 repayBalance = msg.value.sub(tokenPrice.mul(tokensNumber));
            payable(msg.sender).transfer(repayBalance);
        }

        for (uint256 i = 0; i < tokensNumber; i++) {
            uint256 seed = uint256(
                keccak256(
                    abi.encodePacked(
                        uint256(uint160(msg.sender)),
                        uint256(blockhash(block.number - 1)),
                        _tokenIdCounter.current(),
                        "banana"
                    )
                )
            );
            _ages[_tokenIdCounter.current()] = block.timestamp;
            _seeds[_tokenIdCounter.current()] = seed;
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    function buyBananaOwner(uint256 tokensNumber) public onlyOwner {
        require(tokensNumber > 0, "the number is too small");
        require(
            tokensNumber <= maxTokensPerTransaction,
            "number of tokens exceeds the range"
        );
        require(
            _tokenIdCounter.current().add(tokensNumber) <= tokenMaxSupply,
            "number of tokens exceeds the range"
        );

        for (uint256 i = 0; i < tokensNumber; i++) {
            uint256 seed = uint256(
                keccak256(
                    abi.encodePacked(
                        uint256(uint160(msg.sender)),
                        uint256(blockhash(block.number - 1)),
                        _tokenIdCounter.current(),
                        "banana"
                    )
                )
            );
            _ages[_tokenIdCounter.current()] = block.timestamp;
            _seeds[_tokenIdCounter.current()] = seed;
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }
}

library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";
        uint256 encodedLen = 4 * ((len + 2) / 3);
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;
        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}
