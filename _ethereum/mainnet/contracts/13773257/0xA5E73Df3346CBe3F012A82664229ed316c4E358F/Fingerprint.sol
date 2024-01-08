// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721Burnable.sol";

contract Fingerprint is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;

    struct Palette {
        string bg;
        string fg;
        string accent;
        string bgName;
        string fgName;
    }

    struct Density {
        uint8 value;
        string name;
    }

    struct Image {
        uint8 droplets;
        string image;
    }

    struct PreRendered {
        string line1;
        string line2;
        string circle;
    }

    struct PrecalculatedValues {
        uint256 minter;
        Palette palette;
        Density density;
        uint8 lines;
        uint256 fullSize;
        bool isOutline;
        bool isRekt;
        uint8 chunkSize;
        uint16 size;
        uint16 strokeWidth;
        uint16 r;
        string strokeWidthStr;
        string outlineStrokeWidthStr;
    }

    struct RowValues {
        uint256 width;
        string widthStr;
        uint256 l1x2;
        uint256 l2x1;
        string l1x2Str;
        string l2x1Str;
        uint16 offset;
        string offsetStr;
        uint16 y1;
        uint16 y2;
        string y1Str;
        string y2Str;
    }

    uint16 constant _canvasWidth = 1920;
    uint16 constant _canvasHeight = 1080;

    string constant _svgPrefix = "<svg viewBox=\\\"0 0 1920 1080\\\" xmlns=\\\"http://www.w3.org/2000/svg\\\"><clipPath id=\\\"clipAll\\\"><rect fill=\\\"%23";
    string constant _svgSuffix = "</g></svg>";

    uint16 private _maxSupply;
    uint256 private _mintPriceWei;

    Counters.Counter private _tokenIdCounter;
    mapping(uint16 => address) private _tokenToMinter;
    mapping(address => uint16) private _minterToToken;

    uint8[5] private _lineCounts;
    uint256[5] private _sizes;
    Density[3] private _densities;
    Palette[4] private _palettes;

    constructor() ERC721("Fingerprint", "FNGRPRNT") {
        _maxSupply = 1024;
        _mintPriceWei = 42_000_000_000_000_000;

        _lineCounts[0] = 20;
        _lineCounts[1] = 10;
        _lineCounts[2] = 8;
        _lineCounts[3] = 5;
        _lineCounts[4] = 4;

        _sizes[0] = 0xFF;
        _sizes[1] = 0xFFFF;
        _sizes[2] = 0xFFFFF;
        _sizes[3] = 0xFFFFFFFF;
        _sizes[4] = 0xFFFFFFFFFF;

        _densities[0] = Density(33, "Open");
        _densities[1] = Density(45, "Regular");
        _densities[2] = Density(60, "Compact");

        _palettes[0] = Palette("f0f0e0", "220022", "dd0000", "Sand", "Ink");
        _palettes[1] = Palette("220022", "f0f0e0", "dd0000", "Ink", "Sand");
        _palettes[2] = Palette("f0f0e0", "2a2a2a", "ff6607", "Sand", "Graphite");
        _palettes[3] = Palette("2a2a2a", "f0f0e0", "ff6607", "Graphite", "Sand");
    }

    function initialConfig() external view returns(uint256[3] memory) {
        uint256[3] memory result;
        result[0] = _maxSupply;
        result[1] = ERC721Enumerable.totalSupply();
        result[2] = _mintPriceWei;
        return result;
    }

    function updateMintPriceWei(uint256 priceWei) external onlyOwner {
        _mintPriceWei = priceWei;
    }

    function updateMaxSupply(uint16 maxSupply) external onlyOwner {
        require(maxSupply >= ERC721Enumerable.totalSupply(), "Can't reduce supply below total supply");
        require(maxSupply < _maxSupply, "Can't increase supply");
        _maxSupply = maxSupply;
    }

    function claim(address to) external onlyOwner {
        _mintInternal(to);
    }

    function mint() external payable {
        require(msg.value >= _mintPriceWei, "Must send at least mintPriceWei");
        _mintInternal(msg.sender);
        _pay(_mintPriceWei);
    }

    function _mintInternal(address to) private {
        require(to != address(0), "Can't mint for zero address");
        require(_tokenIdCounter.current() + 1 <= _maxSupply, "Collection fully minted");

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);

        _tokenToMinter[uint16(tokenId)] = to;
        _minterToToken[to] = uint16(tokenId);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        require(_exists(tokenId), "ERC721: missing token!");
        uint256 minter = uint256(uint160(_tokenToMinter[uint16(tokenId)]));
        uint256 lineIndex = minter % _lineCounts.length;
        uint8 lines = _lineCounts[lineIndex];
        uint16 size = _canvasHeight / lines;
        Density memory density = _densities[minter % _densities.length];
        uint16 strokeWidth = uint16(size * density.value / 100);
        PrecalculatedValues memory precalc = PrecalculatedValues(
            minter,
            _palettes[minter % _palettes.length],
            density,
            lines,
            _sizes[lineIndex],
            minter % 19 < 6,
            minter % 13 < 3,
            160 / lines,
            size,
            strokeWidth,
            strokeWidth / 2,
            _uintToString(strokeWidth),
            _uintToString(strokeWidth - 5)
        );

        Image memory imageObj = _draw(precalc);
        string memory traits = _traits(precalc, imageObj.droplets);

        string memory token = _uintToString(tokenId);
        return string(abi.encodePacked("data:application/json;utf8,{\"id\": \"", token, "\", \"name\": \"Fingerprint #", token, "\", \"description\": \"Abstract interpretation of the minting address as a fingerprint\", \"attributes\": [", traits, "], \"image_data\": \"", imageObj.image, "\", \"external_url\": \"https://obsolete.design/art/collection/fingerprint/gallery/", token, "\"}"));
    }

    function _traits(PrecalculatedValues memory precalc, uint8 droplets) internal pure returns(string memory) {
        string memory colorTraits = string(abi.encodePacked("{\"trait_type\": \"Color\", \"value\": \"", precalc.palette.fgName, "\"},{\"trait_type\": \"Background\", \"value\": \"", precalc.palette.bgName, "\"}"));
        return string(abi.encodePacked(colorTraits, ",{\"trait_type\": \"Density\", \"value\": \"", precalc.density.name, "\"},{\"trait_type\": \"Lines\", \"value\": \"", _uintToString(precalc.lines) ,"\"},{\"trait_type\": \"Style\", \"value\": \"", precalc.isOutline ? "Outlined" : "Solid" , "\"},{\"trait_type\": \"Distortion\", \"value\": \"", precalc.isRekt ? "Rekt" : "Uniform" , "\"},{\"trait_type\": \"Droplets\", \"value\": \"", _uintToString(droplets) , "\"}"));
    }

    function _draw(PrecalculatedValues memory precalc) internal pure returns(Image memory) {
        string memory svg = "";
        uint8 droplets = 0;

        PreRendered memory pre = _preRender(precalc.palette, precalc.r);

        for (uint8 i = 0; i < precalc.lines; i++) {
            uint256 offset = i * precalc.chunkSize;
            Image memory row = _drawRow((precalc.minter >> offset) & precalc.fullSize, i, precalc, pre);
            droplets = droplets + row.droplets;
            svg = string(abi.encodePacked(svg, row.image));
        }
        return _image(droplets, precalc.palette.bg, svg);
    }

    function _image(uint8 droplets, string memory bg, string memory svg) internal pure returns(Image memory) {
        return Image(droplets, string(abi.encodePacked(_svgPrefix, bg, "\\\" x=\\\"0\\\" y=\\\"0\\\" width=\\\"1920\\\" height=\\\"1080\\\"/></clipPath><rect fill=\\\"%23", bg, "\\\" x=\\\"0\\\" y=\\\"0\\\" width=\\\"1920\\\" height=\\\"1080\\\"/><g clip-path=\\\"url(%23clipAll)\\\">", svg, _svgSuffix)));
    }

    function _preRender(Palette memory palette, uint16 r) internal pure returns(PreRendered memory) {
        return PreRendered(string(abi.encodePacked("\\\" x1=\\\"0\\\" stroke-linecap=\\\"round\\\" />")), string(abi.encodePacked("\\\" x2=\\\"1920\\\" stroke-linecap=\\\"round\\\" />")), string(abi.encodePacked("\\\" r=\\\"", _uintToString(r), "\\\" fill=\\\"%23", palette.accent, "\\\" stroke=\\\"none\\\" />")));
    }

    function _drawRow(uint256 chunk, uint8 i, PrecalculatedValues memory precalc, PreRendered memory pre) internal pure returns(Image memory) {
        RowValues memory rowValues = _calcRowValues(chunk, i, precalc);
        uint8 droplets = 0;

        string memory line1 = "";
        string memory line2 = "";
        string memory outline1 = "";
        string memory outline2 = "";
        string memory circle = "";

        if (rowValues.l1x2 > 0) {
            line1 = string(abi.encodePacked("<line stroke=\\\"%23", precalc.palette.fg, "\\\" stroke-width=\\\"", precalc.strokeWidthStr, "\\\" y1=\\\"",  rowValues.y1Str, "\\\" x2=\\\"", rowValues.l1x2Str, "\\\" y2=\\\"", rowValues.y2Str, pre.line1));
        }

        if (rowValues.l2x1 < _canvasWidth) {
            line2 = string(abi.encodePacked("<line stroke=\\\"%23", precalc.palette.fg, "\\\" stroke-width=\\\"", precalc.strokeWidthStr, "\\\" x1=\\\"", rowValues.l2x1Str, "\\\" y1=\\\"", rowValues.y1Str, "\\\" y2=\\\"", rowValues.y2Str, pre.line2));
        }

        if (chunk % 31 == 0) {
            droplets = droplets + 1;
            circle = string(abi.encodePacked("<circle cx=\\\"", rowValues.widthStr, "\\\" cy=\\\"", rowValues.offsetStr, pre.circle));
        }

        if (precalc.isOutline) {
            if (rowValues.l1x2 > 0) {
                outline1 = string(abi.encodePacked("<line stroke=\\\"%23", precalc.palette.bg, "\\\" stroke-width=\\\"", precalc.outlineStrokeWidthStr, "\\\" y1=\\\"",  rowValues.y1Str, "\\\" x2=\\\"", rowValues.l1x2Str, "\\\" y2=\\\"", rowValues.y2Str, pre.line1));
            }

            if (rowValues.l2x1 < _canvasWidth) {
                outline2 = string(abi.encodePacked("<line stroke=\\\"%23", precalc.palette.bg, "\\\" stroke-width=\\\"", precalc.outlineStrokeWidthStr, "\\\" x1=\\\"", rowValues.l2x1Str, "\\\" y1=\\\"", rowValues.y1Str, "\\\" y2=\\\"", rowValues.y2Str, pre.line2));
            }
        }

        return Image(droplets, string(abi.encodePacked(line1, line2, circle, outline1, outline2)));
    }

    function _calcRowValues(uint256 chunk, uint8 i, PrecalculatedValues memory precalc) internal pure returns(RowValues memory) {
        uint256 width = _canvasWidth * chunk / precalc.fullSize;
        uint256 l1x2 = width > precalc.strokeWidth ? width - precalc.strokeWidth : 0;
        uint256 l2x1 = width + precalc.strokeWidth < _canvasWidth ? width + precalc.strokeWidth : _canvasWidth;

        uint16 offset = i * precalc.size + precalc.size / 2;

        uint16 y1 = offset;
        uint16 y2 = offset;

        if (precalc.isRekt) {
            bool rektPositive = width % 2 == 0;
            y1 = rektPositive ? offset + precalc.r : (offset > precalc.r ? offset - precalc.r : 0);
            y2 = rektPositive ? (offset > precalc.r ? offset - precalc.r : 0) : offset + precalc.r;
        }

        return RowValues(
            width,
            _uintToString(width),
            l1x2,
            l2x1,
            _uintToString(l1x2),
            _uintToString(l2x1),
            offset,
            _uintToString(offset),
            y1,
            y2,
            _uintToString(y1),
            _uintToString(y2)
        );
    }

    function _pay(uint256 amount) internal {
        if (msg.value > 0) {
            uint256 refund = msg.value - amount;

            if (refund > 0) {
                payable(msg.sender).transfer(refund);
            }

            payable(owner()).transfer(amount);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
        address minter = _tokenToMinter[uint16(tokenId)];
        delete _tokenToMinter[uint16(tokenId)];
        delete _minterToToken[minter];
    }

    function userConfig() external view returns(uint16, uint16[] memory) {
        uint16[] memory _owned;

        uint256 ownerCount = ERC721.balanceOf(msg.sender);
        if (ownerCount > 0) {
            _owned = new uint16[](ownerCount);
            for (uint i=0;i<ownerCount;i++) {
                _owned[i] = uint16(tokenOfOwnerByIndex(msg.sender, i));
            }
        }

        return (_minterToToken[msg.sender], _owned);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _uintToString(uint256 v) internal pure returns(string memory) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        if (v == 0) {
            return "0";
        }

        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = bytes1(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i);
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - j - 1];
        }
        return string(s);
    }
}
