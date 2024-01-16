// SPDX-License-Identifier: MIT
// Northern Lights by yuk6ra

pragma solidity ^0.8.9;

import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Base64.sol";
import "./Ownable.sol";

contract NorthernLights is ERC721URIStorage, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    uint256 public constant MAX_SUPPLY = 150;

    uint256 public mintPrice = 0.01 ether;
    uint256 public maxPerWallet = 2;
    bool public whitelistSale = false;
    string public description;

    mapping (address => uint256) public mintedPerWallet;
    mapping (address => bool) public whitelist;

    Counters.Counter private _tokenId;

    constructor() ERC721("NorthernLights", "NLIGHTS") {}

    function addWhitelist(address[] calldata _addresses) external onlyOwner{
        for (uint i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
    }

    function setDescription(string memory _description) external onlyOwner {
        description = _description;
    }

    function setMintPrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    function setMaxPerWallet(uint256 _newQuantity) external onlyOwner {
        maxPerWallet = _newQuantity;
    }

    function setWhitelistSale(bool _bool) external onlyOwner{
        whitelistSale = _bool;
    }    

    function withdraw() external onlyOwner{
        require(address(this).balance > 0, 'No balance');
        require(payable(msg.sender).send(address(this).balance));
    }

    function reservedMint(uint256 _mintAmount) external onlyOwner {
        require(_tokenId.current() + _mintAmount <= MAX_SUPPLY, "Sold out");

        for (uint256 i = 0; i < _mintAmount; i++){
            _safeMint(msg.sender, _tokenId.current());
            _tokenId.increment();
        }
    }

    function mintNFT() public payable {
        require(whitelistSale, "Mint is paused");
        require(whitelist[msg.sender], "No whitelist");
        uint256 tokenId = _tokenId.current();
        require(tokenId < MAX_SUPPLY, "Sold out");
        require(mintedPerWallet[msg.sender] < maxPerWallet, "Already minted max quantity per wallet");
        require(msg.value >= mintPrice, "Must send the mint price");

        _safeMint(msg.sender, tokenId);
        mintedPerWallet[msg.sender] += 1;
        _tokenId.increment();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "NorthernLights: Nonexistent token");
        return dataURI(tokenId);
    }

    /**
     * @notice Generate metadata for TokenURI.
     */
    function dataURI(uint256 tokenId) public view returns(string memory){
        require(_exists(tokenId), "NorthernLights: Nonexistent token");
        string memory name = string(abi.encodePacked('NFT #', tokenId.toString())); // NFT title        
        string[7] memory attr = ["The Earth", "Teegarden's Star b", "TOI-700 d", "Kepler-1649 c", "TRAPPIST-1 d", "K2-72e", "Proxima Centauri b"];
        bytes memory image;
        uint256 attrNum;
        (image, attrNum) = _generateSVG(tokenId);
        return string(
            abi.encodePacked('data:application/json;base64,',
            Base64.encode(bytes(abi.encodePacked(
                '{"name":"', name,
                '", "description": "', description,
                '", "image" : "data:image/svg+xml;base64,', Base64.encode(image),
                '", "attributes" : [{"trait_type": "Planet", "value": "', attr[attrNum],
                '"}]}'
            )))
            )
        );
    }

    /**
     * @notice Get default colors for The Earth Property.
     */
    function _getColors(uint256 seed) internal pure returns (string[8] memory, uint256) {
        string[8] memory colors;

        if (seed % 2 == 0) {
            colors = ["#ab00d1", "#9314d8", "#7a29de", "#623de5", "#4952eb", "#3166f2", "#187bf8", "#008fff"];
        } else if (seed % 2 == 1){
            colors = ["#e900bd", "#cc21ab", "#af4399", "#926487", "#758575", "#58a663", "#3bc851", "#1ee93f"];
        }

        uint256 attrNum = 0;
        return (colors, attrNum);
    }

    /**
     * @notice Generate RGB colors at random.
     */
    function _generateRGB(uint256 seed) internal pure returns (uint256[3] memory) {
        uint256[3] memory rgb;

        for (uint256 i = 0 ; i < 3; i++) {
            rgb[i] = seed % 256;
            seed /= 1000;
        }

        return rgb;
    }

    /**
     * @notice Generate a linear gradient from the first and last RGB.
     */
    function _generateColors(uint256 seed) internal pure returns (string[8] memory, uint256) {
        string[8] memory colors;
        uint256[3] memory first = _generateRGB(seed);
        uint256[3] memory last = _generateRGB(seed / 10**10);

        colors[0] = string(abi.encodePacked('rgb(',first[0].toString(), ',', first[1].toString(), ',', first[2].toString(),')'));

        for (uint256 i = 1; i < 7; i++) {
            colors[i] = string(abi.encodePacked(
                'rgb(',
                ((last[0] * i + (first[0] * (7 - i))) / 7).toString(), ',',
                ((last[1] * i + (first[1] * (7 - i))) / 7).toString(), ',',
                ((last[2] * i + (first[2] * (7 - i))) / 7).toString(),')'));
        }

        uint256 attrNum = seed % 6 + 1;

        colors[7] = string(abi.encodePacked('rgb(',last[0].toString(), ',', last[1].toString(), ',', last[2].toString(),')'));

        return (colors, attrNum);
    }
    
    /**
     * @notice Generate paths for main.
     */    
    function _generateMainPath(uint256 x, uint256 y, bytes memory path, string[8] memory colors) internal pure returns (bytes memory) {
        for (uint256 j = 0; j < 8; j++){
            path = abi.encodePacked(path,
                '<path fill="', colors[j % 8],'" d="M', x.toString(),',', (y + j).toString(),'h1v1H', x.toString(),'z"/>'
            );
        }
        return path;
    }

    /**
     * @notice Generates paths for both ends.
     */    
    function _generateEndsPath(uint256 x, uint256 y, bytes memory path, string[8] memory colors, uint256 num) internal pure returns (bytes memory) {
        bytes memory _path = path;

        if (num == 0 || num == 19) {
            for (uint256 i = 0; i < 4; i++){
                _path = abi.encodePacked(_path,
                    '<path fill="', colors[i % 8],'" d="M', x.toString(),',', (y + i).toString(),'h1v1H', x.toString(),'z"/>'
                );
            }
        } else if(num == 1 || num == 18) {
            for (uint256 j = 0; j < 6; j++){
                _path = abi.encodePacked(_path,
                    '<path fill="', colors[j % 8],'" d="M', x.toString(),',', (y + j).toString(),'h1v1H', x.toString(),'z"/>'
                );
            }
        }

        return _path;
    }

    /**
     * @notice Generate SVG that will be the metadata image.
     */
    function _generateSVG(uint256 tokenId) internal pure returns (bytes memory, uint256) {
        uint256 seedPos = _random(tokenId);
        uint256 seedCol = _random(seedPos);
        uint256 lasty = 8 + seedCol % 13; // Start y position => y = 8 ~ 20.
        uint256 attrNum;
        uint256 x;
        uint256 y;

        string[8] memory colors;
        
        if (_random(seedPos) % 10 >= 1) {
            (colors, attrNum) = _generateColors(seedCol);
        } else {
            (colors, attrNum) = _getColors(seedCol / 10);
        }
         
        bytes memory path = abi.encodePacked('<svg width="1024" height="1024" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg">');
            
        for (uint256 i = 0; i < 20; i++){
            x = 6 + i; // Start x position => x = 6 ~ 25.
            y = lasty; // Last y position.

            if (1 < i && i < 18 ) {
                path = _generateMainPath(x, y, path, colors);
            } else {
                path = _generateEndsPath(x, y, path, colors, i);
            }

            if (seedPos % 2 == 0) { // if 0 => up
                y = lasty - (seedPos % 2 + 1);
                if (y < 6) { // y = 0 ~ 5 (len: 6) => top margin.
                    y = lasty + (seedPos % 2 + 1);
                }
            } else if (seedPos % 2 == 1) { // if 1 => down
                y = lasty + (seedPos % 2 + 1);
                if (18 < y) { // y = 26 ~ 31 (len: 6), + MainPath (len: 8) => bottom margin.
                    y = lasty - (seedPos % 2 + 1);
                }
            }

            lasty = y; // Update the last y position.
            seedPos /= 10; // New random seed.
       }
        path = abi.encodePacked(path, '</svg>');

        return (path, attrNum);
    }
    
    function _random(uint256 _input) internal pure returns(uint256){
        return uint256(keccak256(abi.encodePacked(_input)));
    }
}