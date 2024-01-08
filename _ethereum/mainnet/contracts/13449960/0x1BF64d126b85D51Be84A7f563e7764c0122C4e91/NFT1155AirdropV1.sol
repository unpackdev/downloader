// SPDX-License-Identifier: MIT

pragma solidity =0.8.3;

import "./Ownable.sol";
import "./INFT1155.sol";
import "./INFTLockable.sol";
import "./MerkleProof.sol";

contract NFT1155AirdropV1 is Ownable, MerkleProof {
    address public immutable nftContract;
    mapping(uint256 => bytes32) public merkleRoots;
    mapping(bytes32 => mapping(address => bool)) public claimed;

    event AddMerkleRoot(bytes32 indexed merkleRoot, uint256 indexed tokenId);
    event Claim(bytes32 indexed merkleRoot, uint256 indexed tokenId, address indexed account);

    constructor(
        address _nftContract,
        bytes32 merkleRoot,
        uint256 tokenId
    ) {
        nftContract = _nftContract;
        if (merkleRoot != bytes32("")) {
            merkleRoots[tokenId] = merkleRoot;

            emit AddMerkleRoot(merkleRoot, tokenId);
        }
    }

    function setRoyaltyFeeRecipient(address _royaltyFeeRecipient) external onlyOwner {
        INFT1155(nftContract).setRoyaltyFeeRecipient(_royaltyFeeRecipient);
    }

    function setRoyaltyFee(uint8 _royaltyFee) external onlyOwner {
        INFT1155(nftContract).setRoyaltyFee(_royaltyFee);
    }

    function setURI(uint256 tokenId, string memory uri) external onlyOwner {
        INFT1155(nftContract).setURI(tokenId, uri);
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        INFT1155(nftContract).setBaseURI(baseURI);
    }

    function setLocked(bool locked) external onlyOwner {
        INFTLockable(nftContract).setLocked(locked);
    }

    function mintBatch(
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) external onlyOwner {
        INFT1155(nftContract).mintBatch(to, tokenIds, amounts, data);
    }

    function burnBatch(uint256[] calldata tokenIds, uint256[] calldata amounts) external onlyOwner {
        INFT1155(nftContract).burnBatch(tokenIds, amounts);
    }

    function addMerkleRoot(bytes32 merkleRoot, uint256 tokenId) external onlyOwner {
        require(merkleRoots[tokenId] == bytes32(""), "SHOYU: DUPLICATE_ROOT");
        merkleRoots[tokenId] = merkleRoot;

        emit AddMerkleRoot(merkleRoot, tokenId);
    }

    function claim(
        bytes32 merkleRoot,
        uint256 tokenId,
        bytes32[] calldata merkleProof
    ) external {
        require(merkleRoots[tokenId] == merkleRoot, "SHOYU: INVALID_ROOT");
        require(!claimed[merkleRoot][msg.sender], "SHOYU: FORBIDDEN");
        require(verify(merkleRoot, keccak256(abi.encodePacked(msg.sender)), merkleProof), "SHOYU: INVALID_PROOF");

        claimed[merkleRoot][msg.sender] = true;
        INFT1155(nftContract).mint(msg.sender, tokenId, 1, "");

        emit Claim(merkleRoot, tokenId, msg.sender);
    }
}
