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
    string  public BaseImageURI;                        // BaseURI of gifs
    bytes32 public MerkleRoot;                          // Merkle root hash to verify pre-sale address 
    address public MetadataAddress;                     // The address of metadata's contract
    address public BattleAddress;                       // The address of game's contract
    mapping (address => bool)       ClaimedMapping;     // Mapping pre-sale claimed rewards
    mapping (uint256 => uint256)    MetadataMapping;    // Mapping token's metadata
    uint256 constant STATS_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000000000000000; // Mask for separate props and stats

    constructor(address metadataAddress) ERC721("Astra Chipmunks Genesis", "ACG") {
        MetadataAddress = metadataAddress;
        _safeMint(0x01aDA506B3ce4874F6443c4d0DD2EB35002097c7, 1);
    }

    // The function that reassigns a global variable named MetadataAddress (owner only)
    function setMetadataAddress(address metadataAddress) external onlyOwner {
        MetadataAddress = metadataAddress;
    }

    // The function that reassigns a global variable named BattleAddress (owner only)
    function setBattleAddress(address battleAddress) external onlyOwner {
        BattleAddress = battleAddress;
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
        return IAstraMetadata(MetadataAddress).tokenURI(tokenId, MetadataMapping[tokenId], false, super.tokenURI(tokenId));
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
    
    // Setting the stats of the token
    function setStats(uint256 tokenId, uint256 meta) external {
        // The sender must be game contract
        require(msg.sender == BattleAddress, 'Not authorized!');
        // Put on a mask to make sure nothing can change the art, just stats
        MetadataMapping[tokenId] = (MetadataMapping[tokenId] & ~STATS_MASK) | (meta & STATS_MASK);
    }
}