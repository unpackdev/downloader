//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./base64.sol";
import "./strings.sol";


interface IPunksData {
    function punkAttributes(uint16 index) external view returns (string memory);
    function punkImageSvg(uint16 index) external view returns (string memory);
    function punkImage(uint16 index) external view returns (bytes memory);
}


contract VisitorPunks is ERC721, Ownable {
    using strings for *;

    address payable public beneficiary;
    mapping(uint256 => uint256) public distortionLevel;
    uint16 public nextTokenId = 0;
    string public description = 'A Doppelganger Punk from another dimension. They can look deceptively real, but usually give themselves away. Blink, and you\'ll miss it.';
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    IPunksData data = IPunksData(0x16F5A35647D6F03D5D3da7b35409D65ba03aF3B2);

    constructor() ERC721("Visitor Punks", "VPUNK") {
        beneficiary = payable(0xC1987f61BDCB5459Afc2C835A66D16c844fd7a54); // the mint fund
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId);
    }

    // LarvaLabs can change the beneficiary
    function setBeneficiary(address payable newBeneficiary) public {
        require(msg.sender == 0xC352B534e8b987e036A93539Fd6897F53488e56a, 'nope');
        beneficiary = newBeneficiary;
    }

    // OpenSea royalties accumulate in the contract
    function withdraw() public {
        beneficiary.transfer(address(this).balance);
    }

    function royaltyInfo(uint256, uint256 value) public view returns (address receiver, uint256 royaltyAmount) {
        receiver = beneficiary;
        royaltyAmount = (value * 500) / 10000;
    }

    function setDistortion(uint16 tokenIdx, uint256 level) public {
        require(msg.sender == ownerOf(tokenIdx), 'nope');
        require(level >= 0 && level <= 20, 'must be between 0 and 20');
        distortionLevel[tokenIdx] = level;
    }

    function setDescription(string memory newDescription) public onlyOwner {
        description = newDescription;
    }

    function setPunkData(IPunksData newData) public onlyOwner {
        data = newData;
    }

    function mint() public {
        uint16 tokenId = nextTokenId;
        require(tokenId < 10000, 'max tokens');

        distortionLevel[tokenId] = 5 + uint(keccak256(abi.encode(
            msg.sender,
            block.timestamp,
            blockhash(block.number - 1),
            tokenId
        ))) % 10;

        nextTokenId = nextTokenId + 1;
        _safeMint(msg.sender, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "nonexistent token");
        return constructTokenURI(uint16(tokenId));
    }

    function constructTokenURI(uint16 tokenIdx) public view returns (string memory) {
        string memory name = string(abi.encodePacked('Visitor Punk #', Strings.toString(tokenIdx)));
        bytes memory attributes = getAttributes(data.punkAttributes(tokenIdx));

        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"', name,
                            '", "description":"', abi.encodePacked(description),
                            '", "attributes": [', attributes, ']',
                            ', "image": "',
                            'data:image/svg+xml;base64,',
                            Base64.encode(bytes(getSVG(tokenIdx))),
                            '"}'
                        )
                    )
                )
            )
        );
    }

    function getAttributes(string memory attrString) private view returns (bytes memory) {
        strings.slice memory s = attrString.toSlice();
        strings.slice memory delim = ",".toSlice();

        string memory headType = s.split(delim).toString();
        bytes memory attributes = abi.encodePacked(
            '{"trait_type": "Type", "value": "', headType, '"}'
        );

        while(!s.empty()) {
            attributes = abi.encodePacked(
                attributes, ',',
                '{"trait_type": "Accessory", "value": "', s.split(delim).toString() ,'"}'
            );
        }

        return attributes;
    }

    function getSVG(uint16 tokenIdx) public view returns (string memory) {
        bytes memory punkSVG = bytes(punkImageSvg(tokenIdx));

        return string(abi.encodePacked(
            '<svg viewBox="0 0 400 400" xmlns="http://www.w3.org/2000/svg" version="1.2">',
                '<defs>',
                    '<filter id="filter">',
                        '<feTurbulence type="turbulence" baseFrequency="0.02 0.02" numOctaves="1" result="t"/>',
                        '<feDisplacementMap in="SourceGraphic" in2="t" scale="', Strings.toString(distortionLevel[tokenIdx]) ,'" />',
                    '</filter>',
                '</defs>',
                '<g filter="url(#filter)">',
                    // Original is designed for 24x24 so we essentially scale it up
                    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" version="1.2">',
                       punkSVG,
                    '</svg>',
                '</g>',
            '</svg>'
        ));
    }

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    // generate the SVG ourselves, this will likely need less gas than to cut off the SVG header
    function punkImageSvg(uint16 index) public view returns (string memory svg) {
        bytes memory pixels = data.punkImage(index);
        svg = string("");
        bytes memory buffer = new bytes(8);
        for (uint y = 0; y < 24; y++) {
            for (uint x = 0; x < 24; x++) {
                uint p = (y * 24 + x) * 4;
                if (uint8(pixels[p + 3]) > 0) {
                    for (uint i = 0; i < 4; i++) {
                        uint8 value = uint8(pixels[p + i]);
                        buffer[i * 2 + 1] = _HEX_SYMBOLS[value & 0xf];
                        value >>= 4;
                        buffer[i * 2] = _HEX_SYMBOLS[value & 0xf];
                    }
                    svg = string(abi.encodePacked(svg,
                        '<rect x="', Strings.toString(x), '" y="', Strings.toString(y),'" width="1" height="1" shape-rendering="crispEdges" fill="#', string(buffer),'"/>'));
                }
            }
        }
    }
}