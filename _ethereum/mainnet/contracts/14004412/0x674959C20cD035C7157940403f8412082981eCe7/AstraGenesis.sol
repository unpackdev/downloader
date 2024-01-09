// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./SafeMath.sol";

interface IAstraMetadata {
    function tokenURI(uint256 tokenId, uint256 meta, bool isLocking, string memory genesisImageUrl) external view returns (string memory);
    //function generate(uint256 seed) external view returns (uint256, uint256);
}

contract AstraGenesis is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    
    uint256 constant MAX_TOTAL_SUPPLY = 369;            // Maximum limit of tokens in the collection
    string public BaseImageURI;                                //
    bytes32 public MerkleRoot;                          // Merkle root hash to verify pre-sale address 
    mapping (address => bool) ClaimedMapping;           // Mapping pre-sale claimed rewards
    address public MetadataAddress;                     // The address of metadata's contract

    constructor(address metadataAddress) ERC721("Astra Chipmunks Genesis", "ACG") {
        MetadataAddress = metadataAddress;
        _safeMint(0x01aDA506B3ce4874F6443c4d0DD2EB35002097c7, 1);
    }

    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        MerkleRoot = merkleRoot;
    }

    function setBaseImageURI(string memory baseImageURI) external onlyOwner {
        BaseImageURI = baseImageURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return BaseImageURI;
    }

    // Get the tokenURI onchain
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return IAstraMetadata(MetadataAddress).tokenURI(tokenId, 0, false, super.tokenURI(tokenId));
    }

    // Whitelist check proof
    function checkProof(address buyer, uint256 numberOfTokens, bytes32[] memory merkleProof) public view returns (bool) {
        // Calculate the hash of leaf
        bytes32 leafHash = keccak256(abi.encode(buyer, numberOfTokens));
        // Verify leaf using openzeppelin library
        return MerkleProof.verify(merkleProof, MerkleRoot, leafHash);
    }

    // checkClaimed
    function checkClaimed(address claimant) public view returns (bool) {
        return ClaimedMapping[claimant];
    }

    // Whitelist check claimed
    function mint(uint256 numberOfTokens, bytes32[] memory merkleProof) external {
        // The sender must be a wallet
        require(msg.sender == tx.origin, 'Not a wallet!');
        // Exceeded the maximum total supply
        require(0 < numberOfTokens && totalSupply() + numberOfTokens < MAX_TOTAL_SUPPLY, 'Exceed total supply!');
        // You are not on the whitelist
        require(this.checkProof(msg.sender, numberOfTokens, merkleProof), 'Not on the whitelist!');
        // Your promotion has been used
        require(!checkClaimed(msg.sender), 'Already claimed!');
        // Mark the address that has used the promotion
        ClaimedMapping[msg.sender] = true;

        uint256 startIndex = totalSupply() + 1;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            // To the moon
            _safeMint(msg.sender, startIndex + i);
        }
    }
}