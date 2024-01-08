// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";

import "./CityParkArt.sol";

// You are loved!
contract CityParks is ERC721Enumerable, Ownable {

    using SafeMath for uint256;
    using Strings for uint256;
    using Strings for uint8;

    uint public constant maxSupply = 1700;

    CityParkUtils.Art[maxSupply + 1] public cityParks;

    constructor() ERC721("City Parks", "CITYPARKS") {
        _safeMint(msg.sender, 0);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(
            'data:application/json;utf8,',
            '{"name":"City Park #',
                (tokenId).toString(),
            '",',
            '"description":"City Parks are a wonderful expression of fun.",',
            '"image":"',
                _generateImage(tokenId),
            '", "attributes":[',
                getMetadata(tokenId),
            ']',
        '}'));
    }

    function getMetadata(uint256 tokenId) public view returns (string memory) {
        if (tokenId == 0) {
            return string(abi.encodePacked(
                CityParkUtils._wrapTrait("Created By", "yungwknd.eth"),
                ',',CityParkUtils._wrapTrait("Genesis Token", "True"),
                ',',CityParkUtils._wrapTrait("Live Image", "True")
            ));
        }
        return string(abi.encodePacked(
            CityParkUtils._wrapTrait("Trees", cityParks[tokenId].numTrees.toString()),
            ',',CityParkUtils._wrapTrait("UFO", CityParkUtils._boolToString(cityParks[tokenId].hasUFO)),
            ',',CityParkUtils._wrapTrait("Sun", CityParkUtils._boolToString(cityParks[tokenId].hasSun)),
            ',',CityParkUtils._wrapTrait("Fence", CityParkUtils._boolToString(cityParks[tokenId].hasFence)),
            ',',CityParkUtils._wrapTrait("Bricks", CityParkUtils._boolToString(cityParks[tokenId].hasBricks))
        ));
    }

    function mint(uint256 numberOfMints) public payable {
        require(msg.value == numberOfMints.mul(0.03 ether), 'Not enough ETH');
        require(totalSupply().add(numberOfMints) <= maxSupply, 'Not enough left');
        for (uint i = 0; i < numberOfMints; i++) {
            uint mintNum = totalSupply();
            if (mintNum < maxSupply) {
                _safeMint(msg.sender, mintNum);
                _saveImageInfo(cityParks[mintNum], mintNum);
            }
        }
    }

    function _generateImage(uint256 mintNum) private view returns (string memory) {
        CityParkUtils.Art memory artData = cityParks[mintNum];
        if (mintNum == 0) {
            artData.randomTimestamp = uint48(block.timestamp);
            artData.randomDifficulty = uint128(block.difficulty);
            artData.randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, mintNum)));
            artData.numTrees = uint8(CityParkUtils.seededRandom(1, 3, block.timestamp, artData));
            artData.hasUFO = CityParkUtils.seededRandom(1,100,block.timestamp,artData) >= 90;
            artData.hasSun = !artData.hasUFO;
            artData.hasFence = CityParkUtils.seededRandom(1,100,block.difficulty,artData) >= 90;
            artData.hasBricks = !artData.hasFence;
            artData.overrideWhite = CityParkUtils.seededRandom(1,100,block.timestamp + block.difficulty,artData) >= 20;
        }

        return string(abi.encodePacked(
            CityParkUtils._generateHeader(artData.randomDifficulty,artData),
            CityParkUtils._borderRect,
            CityParkArt._generateRug(artData),
            CityParkArt._generateTrees(artData),
            artData.hasUFO ? CityParkArt._generateUFO(artData) : CityParkArt._generateSun(artData),
            artData.hasFence ? CityParkArt._generateAllFences(artData) : CityParkArt._generateAllBricks(artData),
            CityParkUtils._imageFooter
        ));
    }

    function _saveImageInfo(CityParkUtils.Art storage artInfo, uint mintNum) private {
        artInfo.randomTimestamp = uint48(block.timestamp);
        artInfo.randomDifficulty = uint128(block.difficulty);
        artInfo.randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, mintNum)));
        artInfo.numTrees = uint8(CityParkUtils.seededRandom(1,3,1234,artInfo));
        artInfo.hasUFO = CityParkUtils.seededRandom(1,100,8888888,artInfo) >= 90;
        artInfo.hasSun = !artInfo.hasUFO;
        artInfo.hasFence = CityParkUtils.seededRandom(1,100,8888888,artInfo) >= 90;
        artInfo.hasBricks = !artInfo.hasFence;
        artInfo.overrideWhite = CityParkUtils.seededRandom(1,100,12345,artInfo) >= 80;
    }

    function withdraw(address _to, uint amount) public onlyOwner {
        payable(_to).transfer(amount);
    }
}
