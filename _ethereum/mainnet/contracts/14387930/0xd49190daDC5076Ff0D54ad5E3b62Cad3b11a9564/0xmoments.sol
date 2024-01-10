// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ERC1155.sol";
import "Ownable.sol";


contract Oxmoments is ERC1155, Ownable {
    string private baseURLImage;
    mapping(uint256 => string) private tokenToLocation;
    mapping(uint256 => string) private tokenToImageLocation;
    mapping(uint256 => string) private tokenToName;
    mapping(uint256 => string) private tokenToDescription;

    constructor(string memory baseURLImageInput) public ERC1155("") {
        baseURLImage = baseURLImageInput;
    }

    function setBaseImageUrl(string memory baseURLImageInput) external onlyOwner {
        baseURLImage = baseURLImageInput;
    }

    function setLocation(uint256 tokenId, string memory location) external onlyOwner {
        tokenToLocation[tokenId] = string(abi.encodePacked(baseURLImage, location));
    }

    function setImageLocation(uint256 tokenId, string memory location) external onlyOwner {
         tokenToImageLocation[tokenId] = string(abi.encodePacked(baseURLImage, location));
    }

    function setDescription(uint256 tokenId, string memory description) external onlyOwner {
        tokenToDescription[tokenId] = description;
    } 

    function mint(uint256 tokenId, string memory name, uint256 quantity) external onlyOwner {
        tokenToName[tokenId] = name;
        _mint(msg.sender, tokenId, quantity, "");
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        string memory nameT = string(abi.encodePacked('{"name": "', tokenToName[tokenId] , '",'));
        string memory animationLocation = string(abi.encodePacked('"animation_url": "', tokenToLocation[tokenId] , '"}'));
        string memory description = string(abi.encodePacked('"description": "', tokenToDescription[tokenId] , '",'));
        string memory imageLocation = string(abi.encodePacked('"image": "', tokenToImageLocation[tokenId] , '",'));

        return string(abi.encodePacked('data:application/json,', nameT, 
            description,
            imageLocation,
            animationLocation));
    }
}
