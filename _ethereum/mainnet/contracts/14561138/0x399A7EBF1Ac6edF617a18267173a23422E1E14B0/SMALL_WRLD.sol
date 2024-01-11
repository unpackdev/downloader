// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract SMALL_WRLD is ERC721A, Ownable, ReentrancyGuard
{
    using Strings for string;

    uint public constant MAX_TOKENS = 8888;
    uint public PRESALE_LIMIT = 2500;
    uint public presaleTokensSold = 0;
    uint public constant NUMBER_RESERVED_TOKENS = 100;
    uint256 public PRICE = 0.088 ether;
    uint public perAddressLimit = 3;

    bool public saleIsActive = false;
    bool public preSaleIsActive = false;
    bool public whitelist = true;
    bool public revealed = false;

    address payable public address1;
    address payable public address2;
    address payable public address3;

    uint public reservedTokensMinted = 0;
    string private _baseTokenURI;
    string public notRevealedUri;
    bytes32 root;
    mapping(address => uint) public addressMintedBalance;

    constructor(address payable _address1, address payable _address2, address payable _address3) ERC721A("SMALL WRLD", "SW") {
        address1 = _address1;
        address2 = _address2;
        address3 = _address3;
    }

    function mintToken(uint256 amount, bytes32[] memory proof) external payable
    {
        require(preSaleIsActive || saleIsActive, "Sale must be active to mint");

        require(!preSaleIsActive || presaleTokensSold + amount <= PRESALE_LIMIT, "Purchase would exceed max supply");
        require(!preSaleIsActive || addressMintedBalance[msg.sender] + amount <= perAddressLimit, "Max NFT per address exceeded");
        require(!whitelist || verify(proof), "Address not whitelisted");

        require(amount > 0 && amount <= 3, "Max 3 NFTs per transaction");
        require(totalSupply() + amount <= MAX_TOKENS - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.value >= PRICE * amount, "Not enough ETH for transaction");
        require(msg.sender == tx.origin, "No transaction from smart contracts!");

        if (preSaleIsActive) {
                presaleTokensSold += amount;
                addressMintedBalance[msg.sender] += amount;
        }

        _safeMint(msg.sender, amount);
    }

    function setPrice(uint256 newPrice) external onlyOwner
    {
        PRICE = newPrice;
    }

    function setPresaleLimit(uint newLimit) external onlyOwner
    {
        PRESALE_LIMIT = newLimit;
    }

    function setPerAddressLimit(uint newLimit) external onlyOwner
    {
        perAddressLimit = newLimit;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function flipSaleState() external onlyOwner
    {
        saleIsActive = !saleIsActive;
    }

    function flipPreSaleState() external onlyOwner
    {
        preSaleIsActive = !preSaleIsActive;
    }

    function flipWhitelistingState() external onlyOwner
    {
        whitelist = !whitelist;
    }

    function mintReservedTokens(address to, uint256 amount) external onlyOwner
    {
        require(reservedTokensMinted + amount <= NUMBER_RESERVED_TOKENS, "This amount is more than max allowed");

        reservedTokensMinted+= amount;
        _safeMint(to, amount);
    }

    function withdraw() external nonReentrant
    {
        require(msg.sender == owner(), "Invalid sender");

        (bool success1, ) = address1.call{value: address(this).balance * 925 / 1000}("");
        (bool success2, ) = address2.call{value: address(this).balance * 667 / 1000}("");
        (bool success3, ) = address3.call{value: address(this).balance}("");
        require(success1 && success2 && success3, "Transfer failed");
    }

    function setRoot(bytes32 _root) external onlyOwner
    {
        root = _root;
    }

    function verify(bytes32[] memory proof) internal view returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, root, leaf);
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(revealed == false)
        {
            return notRevealedUri;
        }

        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }
}
