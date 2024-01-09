// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./AdminControl.sol";
import "./IERC721CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";

import "./IERC721.sol";
import "./Strings.sol";
import "./ERC165.sol";

/**
 * The collector will be collected
 */
contract TheCollectedOne is AdminControl, ICreatorExtensionTokenURI {

    using Strings for uint256;

    address private _creator;
    uint private _tokenId;

    bool public paused;
    uint public mintPrice;
    mapping(uint => uint) private mints;
    uint private numMints = 0;
    address private _collector;
    string private _baseURI;
    string private _previewImage;

    constructor(address creator) {
        _creator = creator;
        _collector = msg.sender;
    }

    function initialize() public adminRequired {
        require(_tokenId == 0, 'Token already minted');
        paused = true;
        _tokenId = IERC721CreatorCore(_creator).mintExtension(msg.sender);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    function togglePause() public {
        require(IERC721(_creator).ownerOf(_tokenId) == msg.sender, "Only collector can toggle pause");
        paused = !paused;
    }

    function setMintPrice(uint price) public {
        require(IERC721(_creator).ownerOf(_tokenId) == msg.sender, "Only collector can set mint price");
        mintPrice = price;
    }

    function mint() public payable {
        require(!paused, 'Minting paused.');
        require(msg.value == mintPrice, "Must pay more.");
        require(numMints + 1 <= 100, "No more mints left.");
        numMints++;
        uint thisToken = IERC721CreatorCore(_creator).mintExtension(msg.sender);
        mints[thisToken] = numMints;
    }

    function setBaseURI(string memory baseURI) public adminRequired {
      _baseURI = baseURI;
    }

    function getAnimationURL(uint tokenId) private view returns (string memory) {
        if (tokenId == _tokenId) {
            return string(abi.encodePacked(_baseURI, "0"));
        }
        return string(abi.encodePacked(_baseURI, mints[tokenId].toString()));
    }

    function setPreviewImageForAll(string memory previewImage) public adminRequired {
        _previewImage = previewImage;
    }

    function getName(uint tokenId) private view returns (string memory) {
        if (tokenId == _tokenId) {
            return "The Collector";
        }
        return string(abi.encodePacked("The Collected #", mints[tokenId].toString()));
    }

    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator, "Invalid token");
        return string(abi.encodePacked('data:application/json;utf8,',
        '{"name":"',
        getName(tokenId),
        '","created_by":"yung wknd","description":"What if the collector was the collected one?","animation":"',
        getAnimationURL(tokenId),
        '","animation_url":"',
        getAnimationURL(tokenId),
        '","image":"',
        _previewImage,
        '","image_url":"',
        _previewImage,
        '"}'));
    }

    /**
     * toss a coin to yung wknd
     * oh valley of plenty 
     */
    function withdraw(address _to) public {
        require(IERC721(_creator).ownerOf(_tokenId) == msg.sender, "Only collector can withdraw");
        require(numMints == 100, "Can only withdraw when sold out");
        // Have you ever waltzed into someone's home and taken something without their permission?
        uint balance = address(this).balance;
        uint tax = balance * 69 / 1000;
        uint kept = balance - tax;

        // The taxman cometh
        payable(_collector).transfer(tax);
        payable(_to).transfer(kept);
    }
}
