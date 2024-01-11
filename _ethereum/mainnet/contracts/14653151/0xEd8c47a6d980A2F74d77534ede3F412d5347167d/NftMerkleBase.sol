// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "./console.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Pausable.sol";
import "./IERC721Metadata.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./NftBakeableMetadata.sol";
import "./MerkleAllowList.sol";
import "./NftTrustedConsumers.sol";
import "./MintPassConsumer.sol";

/// @title base merkle NFT project
contract NftMerkleBase is
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable,
    MerkleAllowList,
    NftBakeableMetadata,
    NftTrustedConsumers,
    Ownable
{
    // Use counter as they are burnable
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    mapping(uint256 => uint256) private _dnaMapping;

    // Payable address can receive Ether
    address payable public payee;
    //Minting fee
    uint256 public fee = 0.03 ether;
    uint256 public maxSupply = 3500;
    uint256 public maxBatchMint = 5;

    constructor(
        address payable payeeAddress,
        string memory envBaseURI,
        string memory name,
        string memory symbol,
        bytes32 merkleRoot
    ) NftBakeableMetadata(envBaseURI, name, symbol) MerkleAllowList(merkleRoot) {
        require(payeeAddress != address(0x0), "payeeAddress Need a valid address");
        payee = payeeAddress;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, IERC165)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            ERC721Enumerable.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    // Used for next token as they are burnable
    function numTokens() public view virtual returns (uint256) {
        return _tokenIdTracker.current();
    }

    function getDna(uint256 tokenId) public view virtual returns (uint256) {
        return _dnaMapping[tokenId];
    }

    function _setDna(uint256 tokenId, uint256 baseDna) internal virtual {
        // Keep previous dna - or modify it
        _dnaMapping[tokenId] = baseDna;
    }

    function setPayee(address payeeAddress) external onlyOwner {
        require(payeeAddress != address(0x0), "Need a valid address");
        payee = payable(payeeAddress);
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(newMaxSupply >= 0, "Need a valid new max supply");
        maxSupply = newMaxSupply;
    }

    function setMaxBatchMint(uint256 newMaxBatchMint) external onlyOwner {
        require(newMaxBatchMint >= 0, "Need a valid new max mint limit");
        maxBatchMint = newMaxBatchMint;
    }

    function setFee(uint256 newFee) external onlyOwner {
        fee = newFee;
    }

    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        _setMerkleRoot(newMerkleRoot);
    }

    function sendFeesToPayee(uint256 transferAmount) public onlyOwner {
        require(transferAmount <= address(this).balance, "transferAmount must be less or equal to the balance");
        payee.transfer(transferAmount);
    }

    function bulkMint(address to, uint256 numberMinted) public payable virtual onlyPublicSale {
        require(numberMinted <= maxBatchMint, "numberMinted must be less than or equal to the maxBatchMinted");
        require(msg.value >= (numberMinted * fee), "Payable must be at least the numberMinted * fee");
        for (uint256 i = 0; i < numberMinted; i++) {
            mint(to);
        }
    }

    function bulkMintMerkle(address to, uint256 numberMinted, bytes32[] calldata proofs) public payable virtual canMint(proofs) {
        require(numberMinted <= maxBatchMint, "numberMinted must be less than or equal to the maxBatchMinted");
        require(msg.value >= (numberMinted * fee), "Payable must be at least the numberMinted * fee");
        for (uint256 i = 0; i < numberMinted; i++) {
            mintMerkle(to, proofs);
        }
    }

    // Create he box and dna that will be used in the unboxing
    function mint(address to) public payable virtual onlyPublicSale {
        require(msg.value >= fee, "Payable must be at least the fee");
        // value checked in modifiers
        _internalMint(to);
    }

    function mintMerkle(address to, bytes32[] calldata proofs) public payable canMint(proofs) {
        require(msg.value >= fee, "Payable must be at least the fee");
        // value checked in modifiers
        _internalMint(to);
    }

        // There isn't really any protection on this and it is assumed to only be called in a safe internal
    // location where the msg.value has already been processed
    function _internalMint(address to) private {
        require(_tokenIdTracker.current() < maxSupply, "Capped out supply of tokens to mint");
        uint256 dna = _random();
        uint256 tokenId = _tokenIdTracker.current();
        _dnaMapping[tokenId] = dna;
        _tokenIdTracker.increment();
        _safeMint(to, tokenId);
    }

    function _random() internal view virtual returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, numTokens())));
    }

    // Duplicate implementations from imported open zepplin contracts
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _baseURI() internal view virtual override(ERC721, NftBakeableMetadata) returns (string memory) {
        return super._baseURI();
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721, NftBakeableMetadata) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        override(ERC721, NftTrustedConsumers)
        returns (bool)
    {
        return super._isApprovedOrOwner(spender, tokenId);
    }

    // Enable controlled access to imports
    function enableAllowList() public onlyOwner {
        _enableAllowList();
    }

    function disableAllowList() public onlyOwner {
        _disableAllowList();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setTokenURI(uint256 tokenId, string calldata token_URI) public onlyOwner {
        _setTokenURI(tokenId, token_URI);
    }

    function unsetTokenURI(uint256 tokenId) public onlyOwner {
        _unsetTokenURI(tokenId);
    }

    function setBaseURI(string calldata baseURI) public onlyOwner{
        _setBaseURI(baseURI);
    }

    function setTrustedConsumer(address addr, bool active) public onlyOwner {
        _setTrustedConsumer(addr, active);
    }
}
