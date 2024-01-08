// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

import "./Util.sol";
import "./Mouth.sol";
import "./Eyes.sol";
import "./Nose.sol";

contract Token is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;
    uint256 private constant maxTokensPerTransaction = 10;
    uint256 private tokenPrice = 0.05 ether;
    uint256 private constant tokenMaxSupply = 303;

    address private _a = 0x919036152224102F223641057770F8895a12c46C;
    address private _b = 0xF9466BE8B026ee4Fe22B69e69D84e95f515320e6;
    address private _c = 0x000001947A9A22D0C77097FF1942E7Cf9385C1Ba;

    ERC721 public banana = ERC721(0xa6DE47a17f35dbDC4f6806De0f538e0a7b744Ea6);

    mapping(address => bool) private activate_address;

    mapping(uint256 => uint256) private _seeds;

    constructor() ERC721("OnChain Halloween", "JOL") {}

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

    function getDiscount(address user) public view returns (uint256) {
        uint256 discount = 0;
        if (!activate_address[user]) {
            discount = banana.balanceOf(user).mul(tokenPrice);
        }
        return discount;
    }

    function getTotalPrice(uint256 tokensNumber) public view returns (uint256) {
        uint256 discont = getDiscount(msg.sender);
        uint256 price = 0;
        if (tokenPrice.mul(tokensNumber) > discont) {
            price = tokenPrice.mul(tokensNumber).sub(discont);
        }
        return price;
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

    function _envelop(string[8] memory params)
        private
        pure
        returns (string memory)
    {
        string[11] memory template;
        template[
            0
        ] = '<?xml version="1.0" encoding="utf-8"?><svg width="800" height="800" xmlns="http://www.w3.org/2000/svg" fill="#000"><defs><radialGradient id="rg1" r="300" gradientUnits="userSpaceOnUse"><stop stop-color="';
        template[1] = '" offset="0"/><stop stop-color="';
        template[
            2
        ] = '" stop-opacity="0" offset=".8"/></radialGradient><filter id="fl1"><feMorphology result="fr1" radius="25" in="SourceGraphic"/><feGaussianBlur stdDeviation="3" in="fr1" result="fr2"/><feOffset dy="30" in="fr2" result="fr3"/><feBlend mode="lighten" in2="fr3" in="SourceGraphic" result="fr5"/><feTurbulence result="fr4" in="SourceGraphic" baseFrequency=".02" numOctaves="1" type="fractalNoise"><animate attributeName="seed" values="1;2;3;4;5;6;7;8;9" dur="1" repeatCount="indefinite"/></feTurbulence><feDisplacementMap in2="fr4" in="fr5" scale="60" yChannelSelector="G"/></filter><radialGradient id="rg4" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="';
        template[3] = '"/><stop stop-color="';
        template[
            4
        ] = '"><animate attributeName="offset" values=".8;1" dur=".2" repeatCount="indefinite"/></stop></radialGradient><radialGradient id="rg5" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="';
        template[
            5
        ] = '"/><stop stop-color="#000"><animate attributeName="offset" values=".9;1" dur=".3" repeatCount="indefinite"/></stop></radialGradient><path id="bd" d="M0,0H800V800H-800Z"/><path id="mo" d="';
        template[6] = '"/><path id="le" d="';
        template[7] = '"/><path id="re" d="';
        template[8] = '"/><path id="ns" d="';
        template[
            9
        ] = '"/><g id="mb"><use href="#bd" fill="#FFF"/><use href="#mo"/><use href="#le"/><use href="#ns"/><use href="#re"/></g><g id="mbs"><use href="#bd" fill="#FFF"/><use href="#mo" transform="translate(0,-20)"/><use href="#ns" /><use href="#le" transform="translate(20,0)"/><use href="#re" transform="translate(-20,0)"/></g><mask id="m1"><use href="#mb"/></mask><mask id="m2"><use href="#mbs"/></mask></defs><use href="#bd" fill="url(#rg5)"/><path fill="url(#rg1)" filter="url(#fl1)" d="M400,350c-55,180-85,170-75,240c10,65,140,70,150,0c10-80-25-65-75-240"/><use href="#bd" mask="url(#m2)" fill="url(#rg4)"/><use href="#bd" mask="url(#m1)" fill="#000"/><circle cx="400" cy="400" r="400" fill="url(#rg5)" opacity=".2"/></svg>';
        string memory output1 = string(
            abi.encodePacked(
                template[0],
                params[0],
                template[1],
                params[1],
                template[2],
                params[0],
                template[3],
                params[1]
            )
        );
        string memory output2 = string(
            abi.encodePacked(
                template[4],
                params[2],
                template[5],
                params[3],
                template[6],
                params[4],
                template[7],
                params[5]
            )
        );
        string memory output3 = string(
            abi.encodePacked(template[8], params[6], template[9])
        );
        string memory output = string(
            abi.encodePacked(output1, output2, output3)
        );
        return output;
    }

    function _getColor(uint256 seeds)
        private
        pure
        returns (string[3] memory, uint256)
    {
        uint256 seed = seeds % 20;
        if (seed == 0) return (["#FF0", "#F00", "#93f"], seed);
        if (seed == 1) return (["#6F0", "#060", "#909"], seed);
        if (seed == 2) return (["#80C", "#C04", "#0ac"], seed);
        if (seed == 3) return (["#099", "#009", "#F90"], seed);
        if (seed == 4) return (["#FF0", "#F00", "#060"], seed);
        if (seed == 5) return (["#6F0", "#060", "#060"], seed);
        if (seed == 6) return (["#80C", "#C04", "#804"], seed);
        if (seed == 7) return (["#099", "#009", "#0CC"], seed);
        if (seed == 8) return (["#F00", "#FC0", "#9F0"], seed);
        if (seed == 9) return (["#F00", "#F0F", "#FF0"], seed);
        return (["#FF0", "#F60", "#900"], 10);
    }

    function _getSVG(uint256[4] memory traits)
        private
        pure
        returns (string memory, uint256[] memory)
    {
        uint256[] memory attr = new uint256[](3);
        string memory mouth;
        string[3] memory colors;
        (colors, attr[0]) = _getColor(traits[0]);
        string[2] memory eyes;
        (eyes, attr[1]) = _getEyes(traits[2]);
        (mouth, attr[2]) = _getMouth(traits[1]);
        string[8] memory params;
        params[0] = colors[0];
        params[1] = colors[1];
        params[2] = colors[2];
        params[3] = mouth;
        params[4] = eyes[0];
        params[5] = eyes[1];
        params[6] = _getNose(traits[3]);
        return (_envelop(params), attr);
    }

    function _getAttributes(uint256[] memory attr)
        private
        pure
        returns (string memory)
    {
        string memory output = string(
            abi.encodePacked(
                '[{ "trait_type": "Color", "value": "',
                Util.toStr(attr[0]),
                '"},{ "trait_type": "Eyes", "value": "',
                Util.toStr(attr[1]),
                '"},{ "trait_type": "Mouth", "value": "',
                Util.toStr(attr[2]),
                '"}]'
            )
        );
        return output;
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
        uint256[4] memory traits;
        traits[0] = seed % 1000;
        traits[1] = (seed /= 1000) % 1000;
        traits[2] = (seed /= 1000) % 1000;
        traits[3] = (seed /= 1000) % 1000;

        string memory output;
        uint256[] memory attr;

        (output, attr) = _getSVG(traits);

        string memory attributes = _getAttributes(attr);

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "OnChain Halloween #',
                        Util.toStr(tokenId),
                        '", "description": "Happy OnChain Halloween!  ","attributes":',
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

    function buy(uint256 tokensNumber) public payable {
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
            getTotalPrice(tokensNumber) <= msg.value,
            "The amount is not enough"
        );
        uint256 price = getTotalPrice(tokensNumber);

        if (msg.value > price) {
            uint256 repayBalance = msg.value.sub(price);
            payable(msg.sender).transfer(repayBalance);
        }

        for (uint256 i = 0; i < tokensNumber; i++) {
            uint256 seed = uint256(
                keccak256(
                    abi.encodePacked(
                        uint256(uint160(msg.sender)),
                        uint256(blockhash(block.number - 1)),
                        _tokenIdCounter.current(),
                        "hid8"
                    )
                )
            );
            _seeds[_tokenIdCounter.current()] = seed;
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }

        activate_address[msg.sender] = true;
    }

    function buyOwner(uint256 tokensNumber) public onlyOwner {
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
                        "hid8"
                    )
                )
            );
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
