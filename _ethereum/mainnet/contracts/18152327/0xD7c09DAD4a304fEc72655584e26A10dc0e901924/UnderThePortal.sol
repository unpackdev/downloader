// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ECDSA.sol";
import "./IERC20.sol";
import "./ERC721.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

//   _   _           _             _____ _            ____            _        _
//  | | | |_ __   __| | ___ _ __  |_   _| |__   ___  |  _ \ ___  _ __| |_ __ _| |
//  | | | | '_ \ / _` |/ _ \ '__|   | | | '_ \ / _ \ | |_) / _ \| '__| __/ _` | |
//  | |_| | | | | (_| |  __/ |      | | | | | |  __/ |  __/ (_) | |  | || (_| | |
//   \___/|_| |_|\__,_|\___|_|      |_| |_| |_|\___| |_|   \___/|_|   \__\__,_|_|
//
contract UnderThePortal is ERC721, Pausable, Ownable {
    using ECDSA for bytes32;
    using Counters for Counters.Counter;
    using Strings for uint256;
    address public immutable apeCoinContract;

    Counters.Counter private _tokenIdCounter;

    string public baseURI;
    uint public apePrice = 2000000000000000000;
    address public pkey;
    address public ckey;
    mapping(address => uint256) claimedMapping;

    event PreKeySet(address indexed _prekey);
    event ClaimKeySet(address indexed _claimkey);
    event Claimed(address indexed _addr, address indexed _to);

    constructor(address _apeCoinContract, string memory _inBaseURI) ERC721("UnderThePortal","UTP") {
        apeCoinContract = _apeCoinContract;
        baseURI = _inBaseURI;
        _pause();
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        string memory base = _baseURI();
        return bytes(base).length > 0 ? string(abi.encodePacked(base, tokenId.toString(),".json")) : "";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function ownerMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function purchase(address to, bool agreeTerms, bytes memory signature) public whenNotPaused {
        require(agreeTerms, "You must agree to the Terms of Service, Terms of Sale, and Privacy Policy");
        bytes32 digest = generateEthDigest(msg.sender);
        require(validateSignature(digest, signature, pkey), "Invalid signature");

        IERC20(apeCoinContract).transferFrom(
            _msgSender(),
            address(this),
            apePrice
        );

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function claim(address to, bool agreeTerms, bytes memory signature) public whenNotPaused {
        require(agreeTerms, "You must agree to the Terms of Service, Terms of Sale, and Privacy Policy");
        require(claimedMapping[msg.sender] < 1, "Can only claim one.");
        bytes32 digest = generateEthDigest(msg.sender);
        require(validateSignature(digest, signature, ckey), "Invalid signature");

        claimedMapping[msg.sender] = claimedMapping[msg.sender] + 1;
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        emit Claimed(msg.sender, to);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }


    /**
     * @notice withdraw any erc-20 tokens from the contract
     * @param coinContract the erc-20 contract address
     */
    function withdraw(address coinContract) external onlyOwner {
        uint256 balance = IERC20(coinContract).balanceOf(address(this));
        if (balance > 0) {
            IERC20(coinContract).transfer(msg.sender, balance);
        }
    }

    function setBaseURI(string memory newbaseURI) external onlyOwner {
        baseURI = newbaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setPKey(address prekey) external onlyOwner {
        pkey = prekey;
        emit PreKeySet(prekey);
    }

    function setCKey(address vkey) external onlyOwner {
        ckey = vkey;
        emit ClaimKeySet(vkey);
    }

    function setApePrice(uint newPrice) external onlyOwner {
        apePrice = newPrice;
    }

    function generateDigest(address sender) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(sender));
    }

    function generateEthDigest(address sender) public pure returns (bytes32) {
        bytes32 digest = generateDigest(sender);
        return digest.toEthSignedMessageHash();
    }

    function validateSignature(bytes32 digest, bytes memory signature, address validKey) public pure returns (bool) {
        return digest.recover(signature) == validKey;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

}
