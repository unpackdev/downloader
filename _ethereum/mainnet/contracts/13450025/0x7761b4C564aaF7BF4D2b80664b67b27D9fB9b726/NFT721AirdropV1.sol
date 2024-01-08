// SPDX-License-Identifier: MIT

pragma solidity =0.8.3;

import "./Ownable.sol";
import "./INFT721.sol";
import "./INFTLockable.sol";
import "./MerkleProof.sol";

contract NFT721AirdropV1 is Ownable, MerkleProof {
    struct TokenIdRange {
        uint256 from;
        uint256 length;
    }

    address public immutable nftContract;
    mapping(bytes32 => TokenIdRange) public tokenIdRanges;
    mapping(bytes32 => uint256) public tokensClaimed;
    mapping(bytes32 => mapping(address => bool)) public claimed;

    event AddMerkleRoot(bytes32 indexed merkleRoot, uint256 indexed fromTokenId, uint256 length);
    event Claim(bytes32 indexed merkleRoot, uint256 indexed tokenId, address indexed account);

    constructor(
        address _nftContract,
        bytes32 merkleRoot,
        uint256 fromTokenId,
        uint256 length
    ) {
        nftContract = _nftContract;
        if (merkleRoot != bytes32("")) {
            tokenIdRanges[merkleRoot].from = fromTokenId;
            tokenIdRanges[merkleRoot].length = length;

            emit AddMerkleRoot(merkleRoot, fromTokenId, length);
        }
    }

    function setRoyaltyFeeRecipient(address _royaltyFeeRecipient) external onlyOwner {
        INFT721(nftContract).setRoyaltyFeeRecipient(_royaltyFeeRecipient);
    }

    function setRoyaltyFee(uint8 _royaltyFee) external onlyOwner {
        INFT721(nftContract).setRoyaltyFee(_royaltyFee);
    }

    function setTokenURI(uint256 tokenId, string memory uri) external onlyOwner {
        INFT721(nftContract).setTokenURI(tokenId, uri);
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        INFT721(nftContract).setBaseURI(baseURI);
    }

    function parkTokenIds(uint256 toTokenId) external onlyOwner {
        INFT721(nftContract).parkTokenIds(toTokenId);
    }

    function mintBatch(
        address to,
        uint256[] calldata tokenIds,
        bytes calldata data
    ) external onlyOwner {
        INFT721(nftContract).mintBatch(to, tokenIds, data);
    }

    function burnBatch(uint256[] calldata tokenIds) external onlyOwner {
        INFT721(nftContract).burnBatch(tokenIds);
    }

    function setLocked(bool locked) external onlyOwner {
        INFTLockable(nftContract).setLocked(locked);
    }

    function addMerkleRoot(
        bytes32 merkleRoot,
        uint256 fromTokenId,
        uint256 length
    ) external onlyOwner {
        require(tokenIdRanges[merkleRoot].length == 0, "SHOYU: DUPLICATE_ROOT");
        tokenIdRanges[merkleRoot].from = fromTokenId;
        tokenIdRanges[merkleRoot].length = length;

        emit AddMerkleRoot(merkleRoot, fromTokenId, length);
    }

    function claim(bytes32 merkleRoot, bytes32[] calldata merkleProof) external {
        TokenIdRange storage range = tokenIdRanges[merkleRoot];
        uint256 length = range.length;
        require(length > 0, "SHOYU: INVALID_ROOT");
        require(!claimed[merkleRoot][msg.sender], "SHOYU: FORBIDDEN");
        require(verify(merkleRoot, keccak256(abi.encodePacked(msg.sender)), merkleProof), "SHOYU: INVALID_PROOF");

        uint256 tokens = tokensClaimed[merkleRoot];
        require(tokens < length, "SHOYU: ALL_CLAIMED");

        uint256 tokenId = range.from + tokens;
        claimed[merkleRoot][msg.sender] = true;
        tokensClaimed[merkleRoot] += 1;
        INFT721(nftContract).mint(msg.sender, tokenId, "");

        emit Claim(merkleRoot, tokenId, msg.sender);
    }
}
