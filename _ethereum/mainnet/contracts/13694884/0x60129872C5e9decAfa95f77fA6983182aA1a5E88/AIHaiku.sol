// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Ownable.sol";
import "./ERC721URIStorage.sol";
import "./ECDSA.sol";

/// @title AI Haiku
/// @author @0xNeon - https://github.com/0xNeon-opensource
/// @notice Collaborate with an AI Poet to create something truly unique.
contract AIHaiku is ERC721URIStorage, Ownable {
    using ECDSA for bytes32;

    uint256 public constant maxSupply = 575;
    uint256 public constant price = 0.01 ether;

    uint256 public tokenCounter;
    address private trueSigner;
    address private payoutAddress;

    mapping(string => bool) tokenUriExists;
    mapping(address => uint256) whitelistedAddressToTimesMinted;

    event CreatedAIHaiku(uint256 indexed tokenId, string tokenURI);

    modifier doesNotExceedMaxSupply() {
        require(totalSupply() < maxSupply, "Max supply has already been minted.");
        _;
    }

    modifier whitelistLimitIsNotReached() {
        require(whitelistedAddressToTimesMinted[msg.sender] < 3, "Number of mints per whitelist reached. Please wait until the public mint.");
        _;
    }

    modifier hasMinimumPayment(uint256 value) {
        require(value >= price);
        _;
    }

    modifier tokenUriDoesNotExist(string memory tokenUri) {
        require(!tokenUriExists[tokenUri], "Token URI exists");
        _;
    }

    modifier ensureValidSignature(string memory message, bytes memory signature, bool isWhitelisted) {
        bytes memory encodedMessage = isWhitelisted ? abi.encodePacked("Whitelisted:", message) : abi.encodePacked(message);
        bytes32 hashedMessage = keccak256(encodedMessage).toEthSignedMessageHash();
        address signer = hashedMessage.recover(signature);
        require(signer == trueSigner, "Message not signed by true signer.");
        _;
    }

    constructor() ERC721("AI Haiku", "HAIKU") {
        tokenCounter = 0;
        trueSigner = 0xDBA800F4Da03Dba3f604268aeC2AD9EB28A055A4;
        payoutAddress = 0x58B21e59fE9A3EDb48874fa7E549579AC6D35728;
    }

    function whitelistMint(string memory tokenUri, bytes memory signature)
        external payable
        hasMinimumPayment(msg.value)
        ensureValidSignature(tokenUri, signature, true)
        whitelistLimitIsNotReached
    {
        mint(tokenUri);
        whitelistedAddressToTimesMinted[msg.sender] = whitelistedAddressToTimesMinted[msg.sender] + 1;
    }

    function publicMint(string memory tokenUri, bytes memory signature)
        external payable
        hasMinimumPayment(msg.value)
        ensureValidSignature(tokenUri, signature, false)
    {
        mint(tokenUri);
    }

    function mint(string memory tokenUri)
        private
        doesNotExceedMaxSupply
        tokenUriDoesNotExist(tokenUri)
    {
        _safeMint(msg.sender, tokenCounter);
        _setTokenURI(tokenCounter, tokenUri);
        tokenCounter = tokenCounter + 1;
        tokenUriExists[tokenUri] = true;
        emit CreatedAIHaiku(tokenCounter, tokenUri);
    }

    function totalSupply() public view returns (uint256) {
        return tokenCounter;
    }

    function updateSignerPublicKey(address newAddress) external onlyOwner {
        trueSigner = newAddress;
    }

    function payout() external onlyOwner {
        payable(payoutAddress).transfer(address(this).balance);
    }
}
