/**
 *Submitted for verification at Etherscan.io on 2023-10-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

library MerkleProof {
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }
    function processMultiProof(
        bytes32[] memory proof,
        bool[]    memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }
        if (totalHashes > 0) {
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }
    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }
    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

contract ClaimTail {    
    address constant public burn_address = 0x000000000000000000000000000000000000dEaD;
    address public token_address = 0xFeeeef4D7b4Bf3cc8BD012D02D32Ba5fD3D51e31;
    address public owner;
    bytes32 public root;
    bool public publicClaim;
    mapping(address => bool) public whitelistUsed;
    
    constructor(){
        owner = msg.sender;        
    }
    modifier onlyOwner(){
        require(msg.sender == owner, "caller is not owner");
        _;
    }    
    function verify(
        bytes32[] memory proof,
        address addr,
        uint256 amount
    ) public view returns (bool) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(addr, amount))));
        require(MerkleProof.verify(proof, root, leaf), "INVALID PROOF");
        return true;
    }
    function Claim(bytes32[] memory proof, uint256 amount) external payable {
        address _to = msg.sender;
        require(publicClaim, "CLAIM_HAS_NOT_STARTED_YET");
        require(verify(proof, _to, amount), "NOT_IN_THE_WHITE_LIST");
        require(whitelistUsed[_to] == false, "ALREADY_USED");

        IERC20(token_address).transfer(_to, amount);

        whitelistUsed[_to] = true;
    }
    function set_token_address(address _token_address) external onlyOwner {
        token_address = _token_address;
    }
    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }
    function flipPublicClaim() external onlyOwner {
        publicClaim = !publicClaim;
    }
    function withdrawTokens() external onlyOwner {
        IERC20(token_address).transfer(msg.sender, IERC20(token_address).balanceOf(address(this)));
    }
    function burnTokens() external onlyOwner {
        IERC20(token_address).transfer(burn_address, IERC20(token_address).balanceOf(address(this)));
    }
}