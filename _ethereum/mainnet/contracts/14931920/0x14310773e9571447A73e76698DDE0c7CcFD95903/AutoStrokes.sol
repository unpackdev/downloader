// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 *
 *████████████████████████████████████████████████████████████████████
 *██▀▄─██▄─██─▄█─▄─▄─█─▄▄─███─▄▄▄▄█─▄─▄─█▄─▄▄▀█─▄▄─█▄─█─▄█▄─▄▄─█─▄▄▄▄█
 *██─▀─███─██─████─███─██─███▄▄▄▄─███─████─▄─▄█─██─██─▄▀███─▄█▀█▄▄▄▄─█
 *▀▄▄▀▄▄▀▀▄▄▄▄▀▀▀▄▄▄▀▀▄▄▄▄▀▀▀▄▄▄▄▄▀▀▄▄▄▀▀▄▄▀▄▄▀▄▄▄▄▀▄▄▀▄▄▀▄▄▄▄▄▀▄▄▄▄▄▀
 * 
 *                                                     𝔟𝔶 🅐🅙🅡🅔🅩🅘🅐
 *
 *   A self contained mechanism to originate and print dynamic line strokes based on 
 *       - token Id 
 *       - secret seed 
 *       - blockchain transactions.
 *   
 *  The tokenURI produces different output based on these factors and the generated art pattern changes constantly
 *  producing unique and rare combinations of stroke color, pattern and origin for each token at a given point.
 *   
 */

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./Base64.sol";
import "./StrokePatternGenerator.sol";


contract AutoStrokes is ERC721A, Ownable {
  
  uint256 maxSupply;
  string secretSeed;

    constructor() ERC721A("AutoStrokes", "as") {}

    function setContractParams(string memory _secretSeed, uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
        secretSeed = _secretSeed;
    }
    
    function mint(address recipient, uint256 quantity) external payable{
        require(totalSupply() + quantity <= maxSupply, "Not enough tokens left");
        require(recipient == owner(), "Only owner can mint the tokens");
        _safeMint(recipient, quantity);
    }
    
    function getUniqueCode(uint256 tokenId, uint occurence) internal view returns (string memory) {
        return Strings.toHexString(uint256(keccak256(abi.encodePacked(tokenId, occurence, secretSeed, block.timestamp, block.difficulty))));
    }

    function _baseURI() internal pure override returns (string memory) {
        return "";
    }

    function getStrokeVariation(uint256 tokenId) internal pure returns(uint8){
        uint8[35] memory variationIndicators = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35];
        return variationIndicators[tokenId % 35];
    }

    
    function getBackgroundDetails(uint256 tokenId) internal pure returns(string memory, string memory){
        string[9] memory backgroundColorCodes = ['2A0A0A', '123456', '033E3E', '000000', '254117', '3b2f2f', '560319', '36013f', '3D0C02'];
        string[9] memory backgroundColorNames = ['Seal Brown', 'Deep Sea Blue', 'Deep Teal', 'Black', 'Forest Green', 'Dark Coffee', 'Dark Scarlet', 'Deep Purple', 'Black Bean'];
        return (backgroundColorCodes[tokenId % 9], backgroundColorNames[tokenId % 9]);
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        uint8 variationIndicator = getStrokeVariation(tokenId);
        uint8 numberOfStrokesToPrint = StrokePatternGenerator.getNumberOfStrokesToPrint(getStrokeVariation(tokenId));
       (string memory x, string memory y, string memory originLineTag, string memory originPlan, string memory description) = StrokePatternGenerator.getStrokeOriginParameters(variationIndicator, tokenId, secretSeed);

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{', getProperties(tokenId,numberOfStrokesToPrint,x,y,originPlan, variationIndicator), '"name": "Auto Strokes #', Strings.toString(tokenId), '", "description": "',description,'", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(printStrokes(tokenId, numberOfStrokesToPrint, x, y, originLineTag))), '"}'))));
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function printStrokes(uint256 tokenId, uint8 numberOfStrokesToPrint, string memory x, string memory y, string memory originLineTag) internal view returns (string memory) {        
        string memory prefixTag = getPrefixTag(tokenId);
        string memory suffixTag = getSuffixTag(x, y);
        string memory uniqueCode = getUniqueCode(tokenId, 1);
        string memory strokeSet = StrokePatternGenerator.getStrokePattern(uniqueCode, x, y, 1, secretSeed);
        string memory strokes = string(abi.encodePacked(prefixTag, originLineTag, strokeSet));

        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 2);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 3);

        if(numberOfStrokesToPrint == 60) {
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 4);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 5);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 6);
        } 

        else if (numberOfStrokesToPrint == 90) {
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 4);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 5);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 6);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 7);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 8);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 9);
        } 
        
        else if (numberOfStrokesToPrint == 120){
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 4);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 5);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 6);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 7);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 8);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 9);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 10);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 11);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 12);
        }

        else if (numberOfStrokesToPrint == 150){
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 4);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 5);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 6);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 7);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 8);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 9);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 10);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 11);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 12);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 13);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 14);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 15);
        }
        return string(abi.encodePacked(strokes,  suffixTag));
    }

    function getUpdatedStrokeSet(uint256 tokenId, string memory strokes ,string memory x, string memory y, uint8 occurence) internal view returns (string memory){
        string memory uniqueCode = getUniqueCode(tokenId, occurence);
        string memory strokeSet = StrokePatternGenerator.getStrokePattern(uniqueCode, x, y, occurence, secretSeed);
        return string(abi.encodePacked(strokes, strokeSet));
    }

    function getPrefixTag (uint256 tokenId) internal pure returns (string memory) {           
        string[3] memory prefixTag;
        prefixTag[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"> <rect width="100%" height="100%" fill="#';
        (string memory colorCode,) = getBackgroundDetails(tokenId);
        prefixTag[1] = colorCode;
        prefixTag[2] = '"/>';
        return string(abi.encodePacked(prefixTag[0], prefixTag[1], prefixTag[2]));
    }

    function getSuffixTag (string memory x, string memory y) internal pure returns (string memory) {
        string[5] memory suffixTag;
        suffixTag[0] = '<circle cx="';
        suffixTag[1] = x;
        suffixTag[2] = '" cy="';
        suffixTag[3] = y;
        suffixTag[4] = '" r="3" stroke="black" fill="white"/></svg>';
        return string(abi.encodePacked(suffixTag[0], suffixTag[1], suffixTag[2], suffixTag[3], suffixTag[4]));
    }

    function getProperties(uint256 tokenId, uint8 numberOfStrokesToPrint, string memory x, string memory y, string memory originPlan, uint8 variationIndicator) internal pure returns (string memory) {
        (,string memory colorName) = getBackgroundDetails(tokenId);
        string memory originBehaviour = StrokePatternGenerator.getOriginBehaviour(variationIndicator);
        return string(abi.encodePacked('"attributes" : [ {"trait_type" : "Background","value" : "', colorName,'"},{"trait_type" : "Origin","value" : "', originBehaviour,'"},{"trait_type" : "Origin Path","value" : "', originPlan,'"},{"trait_type" : "Stroke Count","value" : "',Strings.toString(numberOfStrokesToPrint),'"},{"trait_type" : "Coordinates","value" : "(',x,',',y,')"}],'));
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}