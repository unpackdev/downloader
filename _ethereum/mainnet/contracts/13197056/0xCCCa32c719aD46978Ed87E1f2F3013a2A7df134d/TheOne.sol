//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./VRFConsumerBase.sol";


contract TheOne is ERC721Enumerable, Ownable, VRFConsumerBase {
    using Strings for uint256;

    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 public _price = 0.05 ether;
    uint256 public _preSalePrice = 0.025 ether;
    uint256 public _maxSupply = 10000;
    bool public _preSaleIsActive = false;
    bool public _saleIsActive = false;

    // Arbitrarily big number, bigger than maxSupply
    uint256 public theOne = 50000;

    address author = 0xb5e1eD2bbA3CD5bC63066d355dBBE09fD89FEc2d;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: ETH MAINNET
     * Chainlink VRF Coordinator address: 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952
     * LINK token address:                0x514910771AF9Ca656af840dff83E8264EcF986CA
     * Key Hash: 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445
     */
    constructor() public 
    ERC721("TheOne", "TheOne") 
    VRFConsumerBase(
        0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
        0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
    )
    {
        _safeMint(author, 0);
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = 2.0 * 10 ** 18; // 2.0 LINK (Varies by network)
    }

    /** 
     * Requests randomness 
     */
    function getRandomNumber() internal returns (bytes32 requestId) {
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        pickTheOne(randomness);
    }

    function pickTheOne(uint256 randomness) private {
        require(theOne > _maxSupply, "the_one_already_set");

        uint256 num1 = uint256(keccak256(abi.encode(randomness, 0))) % _maxSupply;
        uint256 num2 = uint256(keccak256(abi.encode(randomness, 1))) % 17000;
        if (num1 < num2) {
            theOne = num1;
        } else {
            theOne = num2;
        }
    }

    function preSaleMint(uint256 mintCount) public payable {
        uint256 supply = totalSupply();

        require(_preSaleIsActive,                       "presale_not_active");
        require(balanceOf(msg.sender) + mintCount <= 3, "presale_wallet_limit_met");
        require(supply + mintCount <= 1000,             "max_token_supply_exceeded");
        require(msg.value >= _preSalePrice * mintCount, "insufficient_payment_value");

        for (uint256 i = 0; i < mintCount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function mint(uint256 mintCount) public payable {
        uint256 supply = totalSupply();

        require(_saleIsActive,                      "sale_not_active");
        require(mintCount <= 10,                    "max_mint_count_exceeded");
        require(supply + mintCount <= _maxSupply,   "max_token_supply_exceeded");
        require(msg.value >= _price * mintCount,    "insufficient_payment_value");

        for (uint256 i = 0; i < mintCount; i++) {
            _safeMint(msg.sender, supply + i);
        }
        if (supply + mintCount == _maxSupply) {
            withdrawAll();
            getRandomNumber();
        }
    }

    function giveaway(address winner) public onlyOwner {
        uint256 supply = totalSupply();

        // Cannot be the last one minted
        require(supply + 1 < _maxSupply,   "max_token_supply_exceeded");

        _safeMint(winner, supply);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory name;
        string[5] memory parts;
        parts[
            0
        ] = '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" preserveAspectRatio="xMinYMin meet" viewBox="0 0 420 420"> <style type="text/css"> <![CDATA[ text { fill: white; font-family: monospace; -webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale; } #one { filter: url(#filter); } ]]> </style> <rect width="100%" height="100%" fill="#222222" /> <defs> <filter id="filter"> <feFlood flood-color="#222222" result="#222222" /> <feFlood flood-color="red" result="flood1" /> <feFlood flood-color="limegreen" result="flood2" /> <feOffset in="SourceGraphic" dx="2" dy="0" result="off1a"/> <feOffset in="SourceGraphic" dx="1" dy="0" result="off1b"/> <feOffset in="SourceGraphic" dx="-1" dy="0" result="off2a"/> <feOffset in="SourceGraphic" dx="-1" dy="0" result="off2b"/> <feComposite in="flood1" in2="off1a" operator="in" result="comp1" /> <feComposite in="flood2" in2="off2a" operator="in" result="comp2" /> <feMerge x="0" width="100%" result="merge1"> <feMergeNode in = "black" /> <feMergeNode in = "comp1" /> <feMergeNode in = "off1b" /> <animate attributeName="y" id = "y" dur ="8s" values = "254px; 254px; 180px; 255px; 180px; 152px; 152px; 200px; 190px; 255px; 255px; 170px; 210px; 190px; 254px; 190px; 220px; 160px; 180px; 254px; 252px" keyTimes = "0; 0.362; 0.368; 0.421; 0.440; 0.477; 0.518; 0.564; 0.593; 0.613; 0.644; 0.693; 0.721; 0.736; 0.772; 0.818; 0.844; 0.894; 0.925; 0.939; 1" repeatCount = "indefinite" /> <animate attributeName="height" id = "h" dur ="8s" values = "10px; 0px; 10px; 30px; 50px; 0px; 10px; 0px; 0px; 0px; 10px; 50px; 40px; 0px; 0px; 0px; 40px; 30px; 10px; 0px; 50px" kyTimes = "0; 0.362; 0.368; 0.421; 0.440; 0.477; 0.518; 0.564; 0.593; 0.613; 0.644; 0.693; 0.721; 0.736; 0.772; 0.818; 0.844; 0.894; 0.925; 0.939; 1" repeatCount = "indefinite" /> </feMerge> <feMerge x="0" width="100%" y="60px" height="150px" result="merge2"> <feMergeNode in = "black" /> <feMergeNode in = "comp2" /> <feMergeNode in = "off2b" /> <animate attributeName="y" id = "y" dur ="8s" values = "253px; 254px; 219px; 203px; 192px; 254px; 228px; 239px; 246px; 250px; 217px; 200px; 246px; 216px; 238px; 192px; 163px; 250px; 250px; 254px;" keyTimes = "0; 0.055; 0.100; 0.125; 0.159; 0.182; 0.202; 0.236; 0.268; 0.326; 0.357; 0.400; 0.408; 0.461; 0.493; 0.513; 0.548; 0.577; 0.613; 1" repeatCount = "indefinite" /> <animate attributeName="height" id = "h" dur = "8s" values = "0px; 0px; 0px; 16px; 16px; 12px; 12px; 0px; 0px; 5px; 10px; 22px; 33px; 11px; 0px; 0px; 10px" keyTimes = "0; 0.055; 0.100; 0.125; 0.159; 0.182; 0.202; 0.236; 0.268; 0.326; 0.357; 0.400; 0.408; 0.461; 0.493; 0.513; 1" repeatCount = "indefinite" /> </feMerge> <feMerge> <feMergeNode in="SourceGraphic" /> <feMergeNode in="merge1" /> <feMergeNode in="merge2" /> </feMerge> </filter> </defs> <g> <text x="50%" y="100" font-size="70" class="base" dominant-baseline="middle" text-anchor="middle">THE</text><text x="50%" y="210" font-size="140" class="base" dominant-baseline="middle" text-anchor="middle" id="one">';

        if (theOne > _maxSupply) {
            name = string(abi.encodePacked("The ??? #", toString(tokenId)));
            parts[1] = "???";
            parts[3] = string(abi.encodePacked("#", toString(tokenId)));
        } else if (tokenId == theOne) {
            name = "The One";
            parts[1] = "One";
            parts[3] = "";
        } else {
            name = string(abi.encodePacked("The None #", toString(tokenId)));
            parts[1] = "None";
            parts[3] = string(abi.encodePacked("#", toString(tokenId)));
        }

        parts[2] = '</text><text x="50%" y="280" font-size="20" class="base" dominant-baseline="middle" text-anchor="middle">';
        parts[4] = '</text></g></svg>';

        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4]
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        name,
                        '", "description": "The One is a fully on-chain collection featuring a single The One image. The One image is revealed only after all 10,000 have been minted.", "image": "data:image/svg+xml;base64,',
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

    function setPrice(uint256 price) public onlyOwner {
        _price = price;
    }

    function preSaleStart() public onlyOwner {
        _preSaleIsActive = true;
    }

    function saleStart() public onlyOwner {
        _saleIsActive = true;
    }

    function retryPickTheOne() public onlyOwner {
        getRandomNumber();
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(author).send(address(this).balance));
    }

    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
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