// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC721.sol";
import "./Ownable.sol";
import "./InfiniteCanvas.sol"; // Import the interface for InfiniteCanvas contract
import "./Based64.sol";

contract Acclivities is ERC721, Ownable {
    InfiniteCanvas private infiniteCanvas; // Instance of InfiniteCanvas contract
    uint256 public constant MAX_SUPPLY = 24; // Maximum supply of gradient tokens
    uint256 private _currentTokenId = 0; // Counter for the current token ID
    mapping(uint256 => uint256[]) private gradientToColors;
    constructor(address _infiniteCanvasAddress) ERC721("Acclivities", "GRADIENT") Ownable(msg.sender) {
        infiniteCanvas = InfiniteCanvas(_infiniteCanvasAddress); // Initialize InfiniteCanvas contract
    }
    function toString(uint256 value) internal pure returns (string memory) {
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
    function currentSupply() public view returns (uint256) {
        return _currentTokenId;
    }
    function totalSupply() public pure returns (uint256) {
        return MAX_SUPPLY;
    }
    // Mint function for gradient tokens
    function mintGradient(string[] memory colors) public payable {
        require(_currentTokenId < MAX_SUPPLY, "Max supply reached");
        require(colors.length >= 2, "At least two colors are required");
        uint256 totalCost = colors.length * infiniteCanvas.mintPrice();
        require(msg.value >= totalCost, "Not enough Ether provided.");
        uint256[] memory colorTokenIds = new uint256[](colors.length);
        // Mint each color in the InfiniteCanvas contract and store the token IDs
        for (uint256 i = 0; i < colors.length; i++) {
            infiniteCanvas.mint{value: infiniteCanvas.mintPrice()}(msg.sender, colors[i]);
            uint256 expectedTokenId = infiniteCanvas.totalSupply();
            if (infiniteCanvas.ownerOf(expectedTokenId) == msg.sender) {
            colorTokenIds[i] = expectedTokenId;
            }
        }
        _currentTokenId++;
        // Store the mapping of gradient token to its color components
        gradientToColors[_currentTokenId] = colorTokenIds;
        // Mint the gradient token
        _mint(msg.sender, _currentTokenId);
    }
    // Function to generate SVG for a gradient token
    function getSvg(uint256 tokenId) public view returns (string memory) {
        require(ownerOf(tokenId) != address(0), "Token does not exist");
        uint256[] memory colorTokenIds = gradientToColors[tokenId];
        require(colorTokenIds.length >= 2, "No colors available for this token");
        string memory svg = '<svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg">';
        svg = string(abi.encodePacked(svg, '<defs><linearGradient id="grad', toString(tokenId), '">'));
        for (uint256 i = 0; i < colorTokenIds.length; i++) {
            string memory color = infiniteCanvas.getColor(colorTokenIds[i]);
            string memory offset = toString((i * 100) / (colorTokenIds.length - 1));
            svg = string(abi.encodePacked(svg, '<stop offset="', offset, '%" style="stop-color:', color, '"/>'));
        }
        svg = string(abi.encodePacked(svg, '</linearGradient></defs><rect width="100%" height="100%" fill="url(#grad', toString(tokenId), ')"/></svg>'));
        return svg;
    }
    string[24] private tokenNames = [
        "Slope", "Incline", "Gradation", "Ramp", "Ascension",
        "Progression", "Transition", "Elevation", "Rise", "Tilt",
        "Escalation", "Scale", "Spectrum", "Continuum", "Shift",
        "Fade", "Blend", "Nuance", "Mutation", "Flux",
        "Evolution", "Modulation", "Deviation", "Variation"
    ];

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(ownerOf(tokenId) != address(0), "ERC721Metadata: URI query for nonexistent token");
        string memory name = string(abi.encodePacked(tokenNames[tokenId]));
        uint256[] memory colorTokenIds = gradientToColors[tokenId];
        uint256 colorCount = gradientToColors[tokenId].length;
        string memory colorIdsString = "";
        for (uint256 i = 0; i < colorCount; i++) {
            colorIdsString = string(abi.encodePacked(colorIdsString, 
                (i == 0 ? "" : (i < colorCount - 1 ? ", " : " and ")), 
                toString(colorTokenIds[i])));
        }
        string memory description = string(abi.encodePacked(
            name, 
            " (GRADIENT Token #", toString(tokenId), 
            ") was crafted from ", toString(colorCount), 
            " distinct colours from the Infinite Canvas. This gradient is composed of color token #", 
            colorIdsString, "."
        ));
        string memory image = getSvg(tokenId);
        // Create the JSON metadata string
        string memory json = string(abi.encodePacked(
            '{"name": "', name,
            '", "description": "', description,
            '", "image": "data:image/svg+xml;base64,', Based64.encode(bytes(image)),
            '"}'
        ));
        // Encode the JSON metadata string in Base64
        return string(abi.encodePacked('data:application/json;base64,', Based64.encode(bytes(json))));
    }
}
