// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "./console.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Pausable.sol";
import "./IERC721Metadata.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Allowlist.sol";
import "./NftBakeableMetadata.sol";
import "./NftTrustedConsumer.sol";

/// @title base NFT project
contract Nft is
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable,
    Allowlist,
    NftBakeableMetadata,
    NftTrustedConsumer,
    Ownable
{
    // Use counter as they are burnable
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    mapping(uint256 => uint256) private _dnaMapping;

    // Payable address can receive Ether
    address payable public _payee;
    //Minting fee
    uint256 public fee = 0.046 ether;

    uint256 public constant TOTAL_TOKENS = 8888;
    uint256 public constant MAX_BATCH_MINT = 5;

    constructor(
        address payable payeeAddress,
        string memory envBaseURI,
        string memory name,
        string memory symbol
    ) NftBakeableMetadata(envBaseURI, name, symbol) {
        require(payeeAddress != address(0x0), "payeeAddress Need a valid address");
        _payee = payeeAddress;
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
    function numTokens() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function getDna(uint256 tokenId) public view returns (uint256) {
        return _dnaMapping[tokenId];
    }

    function setPayee(address payeeAddress) public onlyOwner {
        require(payeeAddress != address(0x0), "Need a valid address");
        _payee = payable(payeeAddress);
    }

    function setFee(uint256 newFee) public onlyOwner {
        fee = newFee;
    }

    function sendFeesToPayee(uint256 transferAmount) public onlyOwner {
        require(transferAmount <= address(this).balance, "transferAmount must be less or equal to the balance");
        _payee.transfer(transferAmount);
    }

    function bulkMint(address to, uint256 numberMinted) public payable onlyAllowList {
        require(numberMinted <= MAX_BATCH_MINT, "numberMinted must be less than or equal to the maxBatchMinted");
        require(msg.value >= (numberMinted * fee), "Payable must be at least the numberMinted * fee");
        for (uint256 i = 0; i < numberMinted; i++) {
            mint(to);
        }
    }

    // Create he box and dna that will be used in the unboxing
    function mint(address to) public payable onlyAllowList {
        require(msg.value >= fee, "Payable must be at least the fee");
        require(_tokenIdTracker.current() < TOTAL_TOKENS, "Capped out supply of tokens to mint");

        uint256 dna = _random();
        uint256 tokenId = _tokenIdTracker.current();
        _dnaMapping[tokenId] = dna;
        _tokenIdTracker.increment();
        _safeMint(to, tokenId);
    }

    function _random() internal view returns (uint256) {
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
        override(ERC721, NftTrustedConsumer)
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

    function setAllowlistUser(address addr, bool isAllowed) public onlyOwner {
        _setAllowlistUser(addr, isAllowed);
    }

    function addAllowlistAddresses(address[] calldata addrs) public onlyOwner {
        _addAllowlistAddresses(addrs);
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

    function setTrustedConsumer(address addr) public onlyOwner {
        _setTrustedConsumer(addr);
    }
}
