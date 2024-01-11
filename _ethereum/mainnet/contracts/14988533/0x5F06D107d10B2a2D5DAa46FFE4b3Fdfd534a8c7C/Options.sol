//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./MerkleProof.sol";
interface Ryoko {
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address _owner) external view returns (uint256);
}
contract Options{
    uint256 public mintCost;
    string public contractURI;
    uint public blockTime;
    uint256 public maxPublicSupply = 2222;
    uint256 public maxSupply = 4444;
    uint256 public maxMintAmount = 10;
    uint256 public maxClaimPerWallet = 3;
    uint256 public maxWlPerWallet = 1;
    uint256 public holdersMintPerWallet = 1;
    enum Steps {
        Pause,
        PublicSale,
        SoldOut
    }
    Steps public step;
    bool public revealed = true;
    string public notRevealedUri = "ipfs://notrevealedurl";
    string public baseExtension = ".json";
    bytes32 public claimListRoot;
    bytes32 public whiteListRoot;
    mapping(address => bool) public claimedTokens;
    mapping(address => bool) public wlTokens;
    mapping(address => bool) public holdersMinted;
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "caller is contract");
        _;
    }
    modifier callerIsRyokoHolder() {
        require(firstCollection.balanceOf(msg.sender) > 0, "You need Ryoko tokens");
        _;
    }
    modifier publicSaleStep() {
        require(step == Steps.PublicSale, "Public sale off");
        _;
    }
    function claimValid(bytes32[] memory _proof, bytes32 _leaf) public view returns (bool) {
        return MerkleProof.verify(_proof, claimListRoot, _leaf);
    }
    function wlValid(bytes32[] memory _proof, bytes32 _leaf) public view returns (bool) {
        return MerkleProof.verify(_proof, whiteListRoot, _leaf);
    }
    Ryoko public firstCollection = Ryoko(0xdC268F7b4927Cfe7dAa6A5cCe8D52d473B095F13);
}