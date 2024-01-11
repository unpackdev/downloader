// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155Supply.sol";
import "./IERC1155MetadataURI.sol";
import "./IERC2981.sol";
import "./Pausable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

interface Sprites {
  function ownerOf(uint256 tokenId) external view returns (address);
}

interface IERC721CollectionMetadata {
    /* Read more at https://docs.tokenpage.xyz/IERC721CollectionMetadata */
    function contractURI() external returns (string memory);
}

contract SpriteClubStormdrop is ERC1155Supply, IERC721CollectionMetadata, IERC2981, Ownable, Pausable {
    using Strings for uint256;

    bool public isDropActive;
    bytes32 public spriteItemIdMapMerkleRoot;
    mapping(uint256 => uint256) public claimedSpriteItemIdMap;

    string public name;
    string public symbol;
    Sprites public spritesContract;

    uint16 public royaltyBasisPoints;
    string public collectionURI;
    string internal metadataBaseURI;

    uint256 public ITEM_LIMIT = 5;

    constructor(address intitialSpritesContract, string memory initialMetadataBaseURI, string memory initialCollectionURI, uint16 initialRoyaltyBasisPoints)
    ERC1155(initialMetadataBaseURI)
    Ownable() {
        name = "Sprite Club Stormdrop";
        symbol = "ITEM";
        spritesContract = Sprites(intitialSpritesContract);
        collectionURI = initialCollectionURI;
        royaltyBasisPoints = initialRoyaltyBasisPoints;
    }

    // Meta

    function royaltyInfo(uint256, uint256 salePrice) external view override returns (address, uint256) {
        return (address(this), salePrice * royaltyBasisPoints / 10000);
    }

    function contractURI() external view override returns (string memory) {
        return collectionURI;
    }

    // Admin

    function setMetadataBaseURI(string calldata newMetadataBaseURI) external onlyOwner {
        _setURI(newMetadataBaseURI);
    }

    function setCollectionURI(string calldata newCollectionURI) external onlyOwner {
        collectionURI = newCollectionURI;
    }

    function setRoyaltyBasisPoints(uint16 newRoyaltyBasisPoints) external onlyOwner {
        require(newRoyaltyBasisPoints >= 0, 'SpriteClubStormdrop: royaltyBasisPoints must be >= 0');
        require(newRoyaltyBasisPoints < 5000, 'SpriteClubStormdrop: royaltyBasisPoints must be < 5000 (50%)');
        royaltyBasisPoints = newRoyaltyBasisPoints;
    }

    function setSpriteItemIdMapMerkleRoot(bytes32 newSpriteItemIdMapMerkleRoot) external onlyOwner {
        spriteItemIdMapMerkleRoot = newSpriteItemIdMapMerkleRoot;
    }

    function setIsDropActive(bool newIsDropActive) external onlyOwner {
        require(spriteItemIdMapMerkleRoot != 0, 'SpriteClubStormdrop: cannot start if spriteItemIdMapMerkleRoot not set');
        isDropActive = newIsDropActive;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    //  Metadata

    function uri(uint256 tokenId) override public view returns (string memory) {
        require(totalSupply(tokenId) > 0, "SpriteClubStormdrop: query for nonexistent token");
        return string(abi.encodePacked(super.uri(tokenId), Strings.toString(tokenId), ".json"));
    }

    // Minting

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _generateMerkleLeaf(uint256 spriteId, uint256 itemId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(Strings.toString(spriteId), ":", Strings.toString(itemId)));
    }

    function _verifyMerkleLeaf(bytes32 merkleLeaf, bytes32 merkleRoot, bytes32[] calldata proof) internal pure returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, merkleLeaf);
    }

    // NOTE(krishan711): the first item id is 1 not 0 (so we can use 0 as the "unclaimed" item id)
    function claim(uint256[] calldata spriteIds, uint256[] calldata itemIds, bytes32[][] calldata proofs) public {
        for (uint256 i; i < spriteIds.length; i++) {
            uint256 spriteId = spriteIds[i];
            uint256 itemId = itemIds[i];
            bytes32[] calldata proof = proofs[i];
            require(spritesContract.ownerOf(spriteId) == _msgSender(), "SpriteClubStormdrop: not the owner");
            require(isDropActive, "SpriteClubStormdrop: drop not active");
            require(itemId > 0 && itemId <= ITEM_LIMIT, "SpriteClubStormdrop: invalid itemId");
            require(claimedSpriteItemIdMap[spriteId] == 0, "SpriteClubStormdrop: already claimed");
            require(_verifyMerkleLeaf(_generateMerkleLeaf(spriteId, itemId), spriteItemIdMapMerkleRoot, proof), "SpriteClubStormdrop: invalid proof");
            claimedSpriteItemIdMap[spriteId] = itemId;
            _mint(_msgSender(), itemId, 1, "");
        }
    }


}
