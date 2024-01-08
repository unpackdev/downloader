// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";

contract Blocktangles is ERC721Enumerable, Ownable {
    using SafeMath for uint8;
    using SafeMath for uint256;
    using Strings for string;

    // maximum supply of the NFT
    uint256 public constant MAX_TOKENS = 3333;

    // maximum tokens to be pre-minted for giveaways
    uint256 public constant MAX_GIVEAWAY_TOKENS = 42;

    // maximum mints per single transaction
    uint256 public constant MAX_TOKENS_PER_TX = 15;

    // price per NFT token
    uint256 public constant TOKEN_PRICE = 0.05 ether;

    // starting and pausing sale
    bool public isSalePublic = false;

    // only increment this to avoid collisions
    uint256 internal nextTokenId = 0;

    // palettes used to generate images
    bytes12[] internal palettes = [
        bytes12(0x6fe7dd3490de6639a6521262),
        bytes12(0xe4f9f530e3ca11999e40514e),
        bytes12(0x2b2e4ae8454590374953354a),
        bytes12(0xf9ed69f08a5db83b5e6a2c70),
        bytes12(0x071a5208697217b978a7ff83),
        bytes12(0x283149404b69f73859dbedf3),
        bytes12(0xf0f5f9f0f5f9f0f5f9FF0000),
        bytes12(0xf0f5f9f0f5f9f0f5f900FF00),
        bytes12(0xf0f5f9f0f5f9f0f5f90000FF)
    ];

    // store seeds to generate rectangles from
    mapping(uint256 => bytes32) internal seeds;

    string internal baseURI;

    event Minted(
        uint256 indexed tokenId, 
        address indexed owner, 
        uint256 indexed timestamp, 
        uint256 paletteId,
        bytes32 seed
    );


    /*
    Set up the basics
    */

    constructor(string memory _baseURI) ERC721("Blocktangles", "BLKTNGLS") {
        baseURI = _baseURI;
    }


    /*
    Minting logic
    */

    function mint(uint256 _numTokens) external payable {
        require(isSalePublic, "Sale hasn't started yet");
        require(_numTokens > 0 && _numTokens <= MAX_TOKENS_PER_TX, "You can mint minimum 1, maximum 15 tokens");
        require(_numTokens * TOKEN_PRICE <= msg.value, "Not enough ether sent");
        require(totalSupply().add(_numTokens) <= MAX_TOKENS, "Total supply will exceed maximum token limit");

        for (uint256 i = 0; i < _numTokens; i++) {
            // get next token id according to the counter
            nextTokenId++;
            uint256 tokenId = nextTokenId;

            // mint the NFT
            _safeMint(msg.sender, tokenId);

            // generate and store the token seed
            seeds[tokenId] = _generateTokenSeed(tokenId, msg.sender);

            // emit the mint event
            emit Minted(tokenId, msg.sender, block.timestamp, _getPaletteIdByTokenId(tokenId), seeds[tokenId]);
        }
    }

    function mintGiveaway(uint256 _numTokens) external onlyOwner {
        require(isSalePublic == false, "Sale has already started");
        require(totalSupply().add(_numTokens) <= MAX_GIVEAWAY_TOKENS, "Exceeded giveaway supply");

        for (uint256 i = 0; i < _numTokens; i++) {
            // get next token id according to the counter
            nextTokenId++;
            uint256 tokenId = nextTokenId;

            // mint the NFT
            _safeMint(msg.sender, tokenId);

            // generate and store the token seed
            seeds[tokenId] = _generateTokenSeed(tokenId, msg.sender);

            // emit the mint event
            emit Minted(tokenId, msg.sender, block.timestamp, _getPaletteIdByTokenId(tokenId), seeds[tokenId]);
        }
    }


    /*
    NFT generator related code
    */

    function _generateTokenSeed(uint256 _tokenId, address _to) internal virtual view returns (bytes32 seed) {
        // pseudo-randomly generate the image seed
        seed = keccak256(abi.encodePacked(_tokenId, block.timestamp, _to));
        return seed;
    }

    function _getPaletteIdByTokenId(uint256 _tokenId) internal virtual pure returns (uint256 paletteId) {
        paletteId = _tokenId % 4;

        if (_tokenId % 23 == 1)     paletteId = 4;
        if (_tokenId % 101 == 2)    paletteId = 5;
        if (_tokenId % 221 == 0)    paletteId = 6;
        if (_tokenId % 442 == 0)    paletteId = 7;
        if (_tokenId % 663 == 0)    paletteId = 8;

        return paletteId;
    }

    function getPaletteByTokenId(uint256 _tokenId) public virtual view returns (bytes12) {
        require(_exists(_tokenId), "Token ID not found");
        return palettes[_getPaletteIdByTokenId(_tokenId)];
    }

    function getSeedByTokenId(uint256 _tokenId) public virtual view returns (bytes32) {
        require(_exists(_tokenId), "Token ID not found");
        return seeds[_tokenId];
    }

    function generateSVG(uint256 _tokenId) external virtual view returns (string memory svg) {
        require(_exists(_tokenId), "Token ID not found");
        // get token seed and token palette to generate the image from
        bytes32 seed = getSeedByTokenId(_tokenId);
        bytes12 palette = getPaletteByTokenId(_tokenId);

        svg = string(abi.encodePacked(
            "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 512 512'><g transform='scale(32)' shape-rendering='crispEdges'>", 
            string(abi.encodePacked(
                "<rect x='0' y='0' width='16' height='16' fill='",
                _getRGBColor(palette, 3),
                "'/>"
            ))
        ));

        // 32 bytes of the seed render 32 pseudo-random rectangles
        for (uint8 i = 0; i < 32; i++) {
            uint8 s = uint8(seed[i]);
            int8 w = 7;
            int8 h = 7;
            int8 x = int8(s / 16) - 3;
            int8 y = int8(s % 16) - 3;
            if (x < 0) {
                w = w + x;
                x = 0;
            }
            if (y < 0) {
                h = h + y;
                y = 0;
            }
            if (x > 9) {
                w = 16 - x;
            }
            if (y > 9) {
                h = 16 - y;
            }
            svg = string(abi.encodePacked(
                svg,
                "<rect x='",
                Strings.toString(uint8(x)),
                "' y='",
                Strings.toString(uint8(y)),
                "' width='",
                Strings.toString(uint8(w)),
                "' height='",
                Strings.toString(uint8(h)),
                "' fill='",
                _getRGBColor(palette, s % 4),
                "' opacity='0.85'/>"
            ));
        }

        svg = string(abi.encodePacked(svg,"</g></svg>"));
        return svg;
    }


    function _getRGBColor(bytes12 _palette, uint8 _colorIndex) internal pure returns (string memory _rgbColor) {
        _rgbColor = string(abi.encodePacked(
            "rgb(",
            Strings.toString(uint8(_palette[_colorIndex * 3])),
            " ",
            Strings.toString(uint8(_palette[_colorIndex * 3 + 1])),
            " ",
            Strings.toString(uint8(_palette[_colorIndex * 3 + 2])),
            ")"
        ));
        return _rgbColor;
    }


    /*
    Admin functions
    */

    function _baseURI() internal override view returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public virtual onlyOwner {
        baseURI = _newBaseURI;
    }

    function startSale() public onlyOwner {
        isSalePublic = true;
    }

    function pauseSale() public onlyOwner {
        isSalePublic = false;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

}