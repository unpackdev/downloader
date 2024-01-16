// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./SetInBaseERC721.sol";
import "./Counters.sol";

contract SetInAwardsERC721 is SetInBaseERC721 {

    Counters.Counter public counter;

    bool public transerable = true;

    constructor() SetInBaseERC721("SET IN AWARDS", "SIA", "ipfs://", msg.sender, 1000) {}

    mapping(uint => string) public metadata;
    mapping(uint => uint16) public category;

    /**
     * Manager access
     */

    function mint(string memory metadataHash, uint16 nftCategory, address receiver) public onlyManager {

        Counters.increment(counter);
        uint256 tokenId = Counters.current(counter);

        metadata[tokenId] = metadataHash;
        category[tokenId] = nftCategory;

        _mint(receiver, tokenId);
    }

    function mintBulk(string[] memory metadataHashes, uint16[] memory categories, address[] memory receivers) external onlyManager {

        require(metadataHashes.length == receivers.length && metadataHashes.length == categories.length, "SIA: arrays lengths should be equal");

        for (uint i = 0; i < receivers.length; i++) {
            mint(metadataHashes[i], categories[i], receivers[i]);
        }
    }

    function changeCategory(uint tokenId, uint16 newCategory) public onlyManager {

        _requireMinted(tokenId);
        category[tokenId] = newCategory;
    }

    function changeCategoryBulk(uint[] memory tokenIds, uint16[] memory categories) external onlyManager {

        require(tokenIds.length == categories.length, "SIA: arrays lengths should be equal");

        for (uint i = 0; i < tokenIds.length; i++) {
            changeCategory(tokenIds[i], categories[i]);
        }
    }

    function setTransferable(bool _transerable) external onlyManager {

        transerable = _transerable;
    }

    /**
     * Public access
     */

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {

        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, metadata[tokenId])) : "";
    }

    /**
     * Internal
     */

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        
        require(transerable || from == address(0), "SIA: token transfer is turned off");
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
