
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155Holder.sol";
import "./ERC1155.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./AccessControl.sol";

contract EIPAPlug is ERC1155Holder, Ownable, AccessControl {

    struct TokenClaimInfo {
        bool claimActive;
        uint walletLimit;
        uint transactionLimit;
        bytes32 merkleRoot;
        uint unreservedTotal;
        uint unreservedClaimed;
        mapping(address => uint) totalClaimed;
        mapping(address => bool) reservedClaimed; 
    }
    
    bytes32 public constant SUPPORT_ROLE = keccak256("SUPPORT");
    ERC1155 public eipa;
    mapping(uint => TokenClaimInfo) public tokenClaimInfo;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SUPPORT_ROLE, msg.sender);
    }

    function freeClaim(uint tokenId, uint amount) external {
        require(amount <= tokenClaimInfo[tokenId].transactionLimit, "Over transaction limit");
        require(tokenClaimInfo[tokenId].unreservedClaimed + amount <= tokenClaimInfo[tokenId].unreservedTotal, "No more available");
        _claim(tokenId, amount);
        tokenClaimInfo[tokenId].unreservedClaimed += amount;
    }

    function reservedClaim(uint tokenId, uint amount, bytes32[] memory proof) public {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(MerkleProof.verify(proof, tokenClaimInfo[tokenId].merkleRoot, leaf), "Invalid proof");
        require(tokenClaimInfo[tokenId].reservedClaimed[msg.sender] == false, "Already claimed");
        _claim(tokenId, amount);
        tokenClaimInfo[tokenId].reservedClaimed[msg.sender] = true;
    }

    function _claim(uint tokenId, uint amount) internal {
        require(amount > 0, "Must request more than 0");
        require(msg.sender == tx.origin, "No smart contracts");
        require(tokenClaimInfo[tokenId].claimActive, "Claim is not active");
        require(eipa.balanceOf(address(this), tokenId) >= amount, "Not enough left");
        require(tokenClaimInfo[tokenId].totalClaimed[msg.sender] + amount <= tokenClaimInfo[tokenId].walletLimit, "You have already claimed the maximum allowed");
        eipa.safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
        tokenClaimInfo[tokenId].totalClaimed[msg.sender] += amount;
    }

    function setWalletLimit(uint tokenId, uint walletLimit) external onlyRole(SUPPORT_ROLE) {
        tokenClaimInfo[tokenId].walletLimit = walletLimit;
    }

    function setMerkleRoot(uint tokenId, bytes32 merkleRoot) external onlyRole(SUPPORT_ROLE) {
        tokenClaimInfo[tokenId].merkleRoot = merkleRoot;
    }

    function turnOnClaim(uint tokenId) external onlyRole(SUPPORT_ROLE) {
        tokenClaimInfo[tokenId].claimActive = true;
    }

    function turnOffClaim(uint tokenId) external onlyRole(SUPPORT_ROLE) {
        tokenClaimInfo[tokenId].claimActive = false;
    }

    function setUnreservedLimit(uint tokenId, uint unreservedTotal) external onlyRole(SUPPORT_ROLE) {
        tokenClaimInfo[tokenId].unreservedTotal = unreservedTotal;
    }

    function withdraw(uint tokenId, address addr, uint amount) external onlyRole(SUPPORT_ROLE) {
        eipa.safeTransferFrom(address(this), addr, tokenId, amount, "");
    }

    function setEipa(address addr) external onlyRole(SUPPORT_ROLE) {
        eipa = ERC1155(addr);
    }

    function setTokenClaimInfo(uint tokenId, bool claimActive, uint walletLimit, uint transactionLimit, uint unreservedTotal, bytes32 merkleRoot) external onlyRole(SUPPORT_ROLE) {
        TokenClaimInfo storage claimInfo = tokenClaimInfo[tokenId];
        claimInfo.claimActive = claimActive;
        claimInfo.walletLimit = walletLimit;
        claimInfo.transactionLimit = transactionLimit;
        claimInfo.unreservedTotal = unreservedTotal;
        claimInfo.merkleRoot = merkleRoot;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Receiver, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}