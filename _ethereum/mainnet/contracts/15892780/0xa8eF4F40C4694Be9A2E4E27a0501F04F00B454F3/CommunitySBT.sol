
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./MerkleProof.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./IERC5192.sol";

contract CommunitySBT is Ownable, ERC721URIStorage, IERC5192 {

    mapping(bytes32 => bool) public validRoots;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    struct LeafInfo {
        address account;
        string metadataURI;
    }

    struct RootInfo {
        bytes32 merkleRoot;
        string baseMetadataURI;
        uint32 startTimestamp;
        uint32 endTimestamp;
    }

    event RedeemCommunitySBT(LeafInfo leafInfo, uint256 tokenId);
    // should we add timestamps (start,end) so we can use it in the UI?
    event NewValidRoot(RootInfo rootInfo);
    event InvalidatedRoot(bytes32 merkleRoot);
    
    constructor(string memory name, string memory symbol)
    ERC721(name, symbol){}

    /** @notice Araprt from the root, the extra details are not saved and only used for logging 
     */
    function addNewRoot(RootInfo memory rootInfo) public onlyOwner { 
        validRoots[rootInfo.merkleRoot] = true;
        emit NewValidRoot(rootInfo);
    }

    function invalidateRoot(bytes32 merkleRoot) public onlyOwner { 
        validRoots[merkleRoot] = false;
        emit InvalidatedRoot(merkleRoot);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override virtual {
        require(from == address(0), "Soul Bound Token");   
        super._beforeTokenTransfer(from, to, tokenId);  
    }

    function totalSupply() public view returns (uint256) { 
        return _tokenSupply.current();
    }

    function getTokenIdHash(address account, string memory metadataURI) public view returns (bytes32) {
        return keccak256(abi.encodePacked(account, metadataURI));
    }

    /// @inheritdoc IERC5192
    function locked(uint256 tokenId) external override(IERC5192) view returns (bool) {
        return true; // All tokens are locked.
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC5192).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function redeem(LeafInfo memory leafInfo, bytes32[] calldata proof, bytes32 merkleRoot) public returns (uint256) {
        require(_verify(_leaf(leafInfo), proof, merkleRoot), "Invalid Merkle proof"); 

        bytes32 tokenIdHash = getTokenIdHash(leafInfo.account, leafInfo.metadataURI);
        uint256 tokenId = uint256(tokenIdHash);

        _tokenSupply.increment();
        _safeMint(leafInfo.account, tokenId);
        _setTokenURI(tokenId, leafInfo.metadataURI);

        emit RedeemCommunitySBT(leafInfo, tokenId);
        // https://eips.ethereum.org/EIPS/eip-5192
        emit Locked(tokenId);

        return tokenId;
    }

    /// @notice Supports redemption of multiple SBTs in one transaction
    /// @dev Each claim must present its own root and a full proof, even if this involves duplication
    /// @param leafInfos the leaves of the merkle trees from which to claim an SBT
    /// @param proofs the proofs - one bytes32[] for each leaf
    /// @param merkleRoots the merkel roots - one bytes32 for each leaf
    function multiRedeem(LeafInfo[] memory leafInfos, bytes32[][] calldata proofs, bytes32[] memory merkleRoots) public returns (uint256[] memory tokenIds) {

        // Note that where multiple redemptions are being made for the same merkle tree there exist ways to do
        // the proofs more efficiently with less input.
        // See https://github.com/ethereum/consensus-specs/blob/dev/ssz/merkle-proofs.md#merkle-multiproofs
        // and https://github.com/status-im/account-contracts/blob/develop/contracts/cryptography/MerkleMultiProof.sol
        //
        // This could be implemented in some future, enhanced version of this contract
        require(leafInfos.length == proofs.length && leafInfos.length == merkleRoots.length, "Bad input");
        tokenIds = new uint256[](leafInfos.length);

        for (uint256 i=0; i < leafInfos.length; i++) {
            tokenIds[i] = redeem(leafInfos[i], proofs[i], merkleRoots[i]);
        }
        return tokenIds;
    }

    // Each leaf contains: 
    // 1) The account address;
    // 2) The URI for the NFT image;
    // 3) The badge type;
    function _leaf(LeafInfo memory leafInfo)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(leafInfo.account, leafInfo.metadataURI));
    }


    // Verification that the hash of the actor address and information
    // is correctly stored in the Merkle tree i.e. the proof is validated
    function _verify(bytes32 encodedLeaf, bytes32[] memory proof, bytes32 merkleRoot)
    internal view returns (bool)
    {
        require(validRoots[merkleRoot], "Unrecognised merkle root");
        return MerkleProof.verify(proof, merkleRoot, encodedLeaf);
    }

}