// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

// 📸 by yungwknd.eth                                                                                                 
contract SelfieCamera is ERC721Enumerable, Ownable {

    using SafeMath for uint256;
    using Strings for uint256;

    mapping(uint => string) names; // Name of photo
    mapping(uint => string) baseImageURIs; // Future different baseImageURIs
    mapping(uint => string) public cameraScripts; // Allow for future different scripts
    mapping(uint => string) cameraDescription; // Description of the camera
    mapping(uint => string) fileExt; // Each script has its own file extension
    mapping(uint => uint) scriptForToken; // Which script a given token uses
    mapping(uint => uint) photoDates; // When the photo was taken
    mapping(uint => string) fallbackLink; // Fallback link once image expires
    mapping(uint => uint) expiryLength; // How long image lasts for

    event selfieTaken(uint tokenId);

    constructor() ERC721("Selfie Camera", "SELFIE") { }
    
    function photosOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function addBaseImageURI(uint index, string memory baseURI) public onlyOwner {
        baseImageURIs[index] = baseURI;
    }

    function addCameraScript(uint index, string memory script) public onlyOwner {
        cameraScripts[index] = script;
    }

    function addCameraDescription(uint index, string memory script) public onlyOwner {
        cameraDescription[index] = script;
    }

    function addExtension(uint index, string memory ext) public onlyOwner {
        fileExt[index] = ext;
    }

    function setFallbackLink(uint index, string memory link) public onlyOwner {
        fallbackLink[index] = link;
    }

    function setCameraExpiry(uint index, uint expire) public onlyOwner {
        expiryLength[index] = expire;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(
            'data:application/json;utf8,',
            '{"name":"Selfie #',
                (tokenId).toString(),
            '",',
            '"description":"Hey. Take a selfie! ',
                cameraDescription[scriptForToken[tokenId]],
            '",',
            '"image":"',
                getImageURL(tokenId),
            '", "attributes":[',
                _wrapTrait("Subject", names[tokenId]),
                ',',
                _wrapTrait("Camera", scriptForToken[tokenId].toString()),
            ']',
        '}'));
    }

    function getImageURL(uint tokenId) private view returns (string memory) {
        uint photoDate = photoDates[tokenId];
        if (block.timestamp - photoDate > expiryLength[scriptForToken[tokenId]]) {
            return fallbackLink[scriptForToken[tokenId]];
        }
        return string(abi.encodePacked(baseImageURIs[scriptForToken[tokenId]], tokenId.toString(), ".", fileExt[scriptForToken[tokenId]]));
    }

    function takePhoto(string memory name, uint script) public {
        uint tokenId = totalSupply();
        _safeMint(msg.sender, tokenId);
        names[tokenId] = name;
        scriptForToken[tokenId] = script;
        photoDates[tokenId] = block.timestamp;
        emit selfieTaken(tokenId);
    }

    function _wrapTrait(string memory trait, string memory value) internal pure returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            trait,
            '","value":"',
            value,
            '"}'
        ));
    }
}