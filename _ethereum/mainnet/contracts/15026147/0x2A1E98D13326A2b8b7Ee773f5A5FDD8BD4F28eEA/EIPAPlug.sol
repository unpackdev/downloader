//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./IERC1155CreatorCore.sol";

// This contract facilitates the minting of the Eleni is Playing Again collection
// Website: https://isboredagain.com/
// Twitter: https://twitter.com/isboredagain

// Smart Contract Developed By Computer 
// Twitter: https:/twitter.com/ComputerCrypto

contract EIPAPlug is Ownable, AccessControl {

    struct TokenMintInfo {

        // Configuration
        bool mintActive;
        uint walletLimit;
        uint transactionLimit;
        uint maxSupply;
        bytes32 merkleRoot;
        uint unreservedSupply;

        // Tracking
        uint totalMinted;
        uint unreservedClaimed;
        mapping(address => uint) totalClaimed;
        mapping(address => bool) reservationClaimed; 
    }
    
    bytes32 public constant SUPPORT_ROLE = keccak256("SUPPORT");
    IERC1155CreatorCore public eipa;
    mapping(uint => TokenMintInfo) public tokenMintInfo;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SUPPORT_ROLE, msg.sender);
    }

    function freeMint(uint tokenId, uint amount) external {
        TokenMintInfo storage mintInfo = tokenMintInfo[tokenId];
        require(mintInfo.mintActive, "Mint is not active");
        require(amount <= mintInfo.transactionLimit, "Over transaction limit");
        require(mintInfo.unreservedClaimed + amount <= mintInfo.unreservedSupply, "No more available");
        require(mintInfo.totalClaimed[msg.sender] + amount <= mintInfo.walletLimit, "You have already claimed the maximum allowed");
        _mint(msg.sender, tokenId, amount, mintInfo);
        mintInfo.unreservedClaimed += amount;
        mintInfo.totalClaimed[msg.sender] += amount;
    }

    function reservedMint(uint tokenId, uint amount, bytes32[] memory proof) external {
        TokenMintInfo storage mintInfo = tokenMintInfo[tokenId];
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(mintInfo.mintActive, "Mint is not active");
        require(MerkleProof.verify(proof, mintInfo.merkleRoot, leaf), "Invalid proof");
        require(mintInfo.reservationClaimed[msg.sender] == false, "Already claimed");
        require(mintInfo.totalClaimed[msg.sender] + amount <= mintInfo.walletLimit, "You have already claimed the maximum allowed");
        _mint(msg.sender, tokenId, amount, mintInfo);
        mintInfo.reservationClaimed[msg.sender] = true;
        mintInfo.totalClaimed[msg.sender] += amount;
    }

    function _mint(address to, uint tokenId, uint amount, TokenMintInfo storage mintInfo) internal {
        require(amount > 0, "Must request more than 0");
        require(msg.sender == tx.origin, "No smart contracts");
        require(eipa.totalSupply(tokenId) + amount <= mintInfo.maxSupply, "No more mints available");
        require(mintInfo.totalMinted + amount <= mintInfo.maxSupply, "No more mints available");
   
        address[] memory addresses = new address[](1);
        addresses[0] = to;
        uint[] memory tokenIds = new uint[](1);
        tokenIds[0] = tokenId;
        uint[] memory amounts = new uint[](1);
        amounts[0] = amount;
        
        eipa.mintBaseExisting(addresses, tokenIds, amounts);
        mintInfo.totalMinted += amount;
    }

    function setWalletLimit(uint tokenId, uint walletLimit) external onlyRole(SUPPORT_ROLE) {
        tokenMintInfo[tokenId].walletLimit = walletLimit;
    }

    function setMerkleRoot(uint tokenId, bytes32 merkleRoot) external onlyRole(SUPPORT_ROLE) {
        tokenMintInfo[tokenId].merkleRoot = merkleRoot;
    }

    function turnOnMint(uint tokenId) external onlyRole(SUPPORT_ROLE) {
        tokenMintInfo[tokenId].mintActive = true;
    }

    function turnOffMint(uint tokenId) external onlyRole(SUPPORT_ROLE) {
        tokenMintInfo[tokenId].mintActive = false;
    }

    function setUnreservedSupply(uint tokenId, uint unreservedSupply) external onlyRole(SUPPORT_ROLE) {
        tokenMintInfo[tokenId].unreservedSupply = unreservedSupply;
    }

    function gift(uint tokenId, address addr, uint amount) external onlyRole(SUPPORT_ROLE) {
        TokenMintInfo storage mintInfo = tokenMintInfo[tokenId];
        require(eipa.totalSupply(tokenId) + amount <= mintInfo.maxSupply, "Exceeds available supply");
        require(mintInfo.totalMinted + amount <= mintInfo.maxSupply, "No more mints available");
        
        _mint(addr, tokenId, amount, mintInfo);
    }

    function setEipa(address addr) external onlyRole(SUPPORT_ROLE) {
        eipa = IERC1155CreatorCore(addr);
    }

    function setTokenMintInfo(uint tokenId, bool mintActive, uint walletLimit, uint transactionLimit, uint unreservedSupply, uint maxSupply, bytes32 merkleRoot) external onlyRole(SUPPORT_ROLE) {
        TokenMintInfo storage mintInfo = tokenMintInfo[tokenId];
        mintInfo.mintActive = mintActive;
        mintInfo.walletLimit = walletLimit;
        mintInfo.transactionLimit = transactionLimit;
        mintInfo.unreservedSupply = unreservedSupply;
        mintInfo.maxSupply = maxSupply;
        mintInfo.merkleRoot = merkleRoot;
    }

    function reservationClaimed(uint tokenId, address addr) view external returns(bool)  {
        return tokenMintInfo[tokenId].reservationClaimed[addr];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}