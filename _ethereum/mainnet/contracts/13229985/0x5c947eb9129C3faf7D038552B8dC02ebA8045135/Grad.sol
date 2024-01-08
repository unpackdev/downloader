// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721Enumerable.sol";
import "./base64.sol";

// Snake game on the Ethereum blockchain
contract Grad is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    uint256 public maxTokens = 3333;
    uint256 public price = 0.03 ether;
    bool public saleOpen = false;

    mapping(uint256 => address) private _tokenURIToAddress;
    mapping(address => uint256) private _addressToTokenURI;

    constructor() ERC721("Grad", "GRAD") {}

    function getColor(bytes memory _hash, uint256 _start)
        internal
        pure
        returns (
            uint8,
            uint8,
            uint8
        )
    {
        uint8 r = toUint8(_hash, _start);
        uint8 g = toUint8(_hash, _start + 1);
        uint8 b = toUint8(_hash, _start + 2);
        return (r, g, b);
    }

    function getGradient(
        bytes memory _hash,
        uint256 _start,
        string memory gradId
    ) internal pure returns (string memory) {
        (uint256 r1, uint256 g1, uint256 b1) = getColor(_hash, _start);
        (uint256 r2, uint256 g2, uint256 b2) = getColor(_hash, _start + 3);

        return
            string(
                abi.encodePacked(
                    '<linearGradient id="',
                    gradId,
                    '" x1="0%" y1="0%" x2="100%" y2="0%"><stop offset="0%" style="stop-color:rgb(',
                    toString(r1),
                    ",",
                    toString(g1),
                    ",",
                    toString(b1),
                    ');stop-opacity:1"/><stop offset="100%" style="stop-color:rgb(',
                    toString(r2),
                    ",",
                    toString(g2),
                    ",",
                    toString(b2),
                    ');stop-opacity:1"/></linearGradient>'
                )
            );
    }

    string[11] internal shapes = [
        '<rect x="25%" y="25%" width="50%" height="50%" fill="url(#shapeGrad)" stroke="url(#grad)"/>',
        '<circle cx="50%" cy="50%" r="25%" fill="url(#shapeGrad)" stroke="url(#grad)"/>',
        '<polygon points="16 8, 24 24, 8 24" fill="url(#shapeGrad)" stroke="url(#grad)" />',
        '<polygon points="12 8, 20 8, 25 16, 20 24, 12 24, 7 16" fill="url(#shapeGrad)" stroke="url(#grad)" />',
        '<polygon points="16 8, 22 16, 16 24, 10 16" fill="url(#shapeGrad)" stroke="url(#grad)" />',
        '<polygon points="16 8, 24 16, 16 24, 8 16" fill="url(#shapeGrad)" stroke="url(#grad)" />',
        '<polygon points="12 8, 20 8, 24 12, 16 24, 8 12" fill="url(#shapeGrad)" stroke="url(#grad)" />',
        '<polygon points="12 10, 24 10, 20 22, 8 22" fill="url(#shapeGrad)" stroke="url(#grad)" />',
        '<polygon points="16 8, 24 14, 21 23, 11 23, 8 14" fill="url(#shapeGrad)" stroke="url(#grad)" />',
        '<polygon points="16 6, 24 12, 16 24, 8 12" fill="url(#shapeGrad)" stroke="url(#grad)" />',
        '<ellipse cx="16" cy="16" rx="7" ry="10" fill="url(#shapeGrad)" stroke="url(#grad)" />'
    ];

    function toUint8(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint8)
    {
        require(_bytes.length >= _start + 1, "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function getSVG(bytes memory _address) internal view returns (string memory) {
        string[8] memory parts;

        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 32 32">';
        parts[1] = "<defs>";
        parts[2] = getGradient(_address, 0, "grad");
        parts[3] = getGradient(_address, 6, "shapeGrad");
        parts[4] = "</defs>";
        parts[5] = '<rect width="100%" height="100%" fill="url(#grad)"/>';
        parts[6] = shapes[toUint8(_address, 12) % shapes.length];
        parts[7] = "</svg>";

        return
            string(
                abi.encodePacked(
                    parts[0],
                    parts[1],
                    parts[2],
                    parts[3],
                    parts[4],
                    parts[5],
                    parts[6],
                    parts[7]
                )
            );
    }

    function tokenURIForAddress(address _address)
        public
        view
        returns (string memory)
    {
        return getTokenURI(_address, 0);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");
        return getTokenURI(_tokenURIToAddress[tokenId], tokenId);
    }

    function getTokenURI(address _address, uint256 _tokenId)
        internal
        view
        returns (string memory)
    {
        bytes memory addressBytes = abi.encodePacked(_address);

        string memory output = getSVG(addressBytes);

        string memory name = "Grad";
        if (_tokenId == 0) {
            name = string(
                abi.encodePacked(
                    name,
                    " (0x",
                    toAsciiString(_address),
                    ")"
                )
            );
        } else {
            name = string(abi.encodePacked(name, " #", toString(_tokenId)));
        }

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        name,
                        '", "description": "Created from 0x',
                        toAsciiString(_address),
                        '", "image": "data:image/svg+xml;base64,',
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

    function flipSaleState() external onlyOwner {
        saleOpen = !saleOpen;
    }

    function mint() external payable nonReentrant returns (uint256) {
        return internalMint(_msgSender());
    }

    function mintForAddress(address _address) external onlyOwner returns (uint256) {
        return internalMint(_address);
    }

    function internalMint(address _address) internal returns (uint256) {
        require(_addressToTokenURI[_address] == 0, "Already minted");
        require(totalSupply() <= maxTokens, "Exceeds maximum supply");
        if (_msgSender() != owner()) {
            require(saleOpen, "Sale is not open yet");
            require(
                msg.value >= price,
                "Ether sent with this transaction is not correct"
            );
        }

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(_msgSender(), newTokenId);
        _tokenURIToAddress[newTokenId] = _address;
        _addressToTokenURI[_address] = newTokenId;
        return newTokenId;
    }

    function withdrawAll() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function updatePricePerMint(uint256 _price) public onlyOwner {
        price = _price;
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
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
