// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/* 
    8888888888 888     888 888b    888 
    888        888     888 8888b   888 
    888        888     888 88888b  888 
    8888888    888     888 888Y88b 888 
    888        888     888 888 Y88b888 
    888        888     888 888  Y88888 
    888        Y88b. .d88P 888   Y8888 
    888         "Y88888P"  888    Y888 

    Malus Creations
    ---------------------------------------------
    Project: Fractal Universe
    Artist: Fractal United
    ---------------------------------------------
    Developed by ATOMICON.PRO (info@atomicon.pro)
*/

import "./ERC721A_v3.1.0.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract FractalUniverse is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    // Ensures that other contracts can't call a method 
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    uint16 constant public COLLECTION_SIZE = 999;
    uint32 constant public CLAIM_START_TIME = 1648411200;

    bytes8 constant private _hashSalt = 0x396e5a6740627e2d;
    address constant private _signerAddress = 0x0d80a03C234f9464c046481F554FE0948D299F3f;

    address[4] private _payoutWallets = [
        0xAb8da4a15424E0A51B31317f3A69f76f1c4033c1,
        0xEA469f5F95Ec73a9DCF37C729BCBd7dB5d4D1bC9,
        0x7e3F983911eB2740Ba7F685907B68A0044bA9cFF,
        0x9BB75389c8D1d6fDA48c6f8c1daE6Fd3F4bd5DEb
    ];

    // Used nonces for minting signatures    
    mapping(uint64 => bool) private _usedNonces;

    constructor() ERC721A("Fractal Universe by Fractal United", "FUN") {}

    // Claim tokens for free based on a backend whitelist
    function claimMint(bytes32 hash, bytes memory signature, uint256 quantity, uint64 maxTokens, uint64 nonce)
        external
        callerIsUser
    {
        require(isHoldersClaimOn(), "SPF holders claim have not begun yet");
        
        require(totalSupply() + quantity <= COLLECTION_SIZE, "Reached max supply");
        require(numberMinted(msg.sender) + quantity <= maxTokens, "Exceeding claiming limit for this account");

        require(_operationHash(msg.sender, quantity, maxTokens, nonce) == hash, "Hash comparison failed");
        require(_isTrustedSigner(hash, signature), "Direct minting is disallowed");
        require(!_usedNonces[nonce], "Hash is already used");
        
        _safeMint(msg.sender, quantity);
        _usedNonces[nonce] = true;
    }

    // Airdrop tokens to a list of addresses with counts specified in the second argument
    function airdropMint(address[] memory addresses, uint256[] memory tokensCount)
        external 
        onlyOwner
    {
        require(addresses.length == tokensCount.length, "Addresses and tokens count arrays lengths don't match");

        uint256 totalCount = 0;
        for(uint64 i = 0; i < addresses.length; i++) {
            totalCount = totalCount + tokensCount[i];
        }

        require(totalSupply() + totalCount <= COLLECTION_SIZE, "Reached max supply");

        for(uint64 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], tokensCount[i]);
        }
    }

    // Generate hash of current mint operation
    function _operationHash(address buyer, uint256 quantity, uint64 maxTokens, uint64 nonce) internal view returns (bytes32) {        
        return keccak256(abi.encodePacked(
            _hashSalt,
            buyer,
            uint64(block.chainid),
            uint64(maxTokens),
            uint64(quantity),
            uint64(nonce)
        ));
    } 

    // Test whether a message was signed by a trusted address
    function _isTrustedSigner(bytes32 hash, bytes memory signature) internal pure returns(bool) {
        return _signerAddress == ECDSA.recover(hash, signature);
    }

    // Withdraw money for developers and for creators (2% and 98%)
    function withdrawMoney() external onlyOwner nonReentrant {
        require(address(this).balance > 0, "No funds on the contract");

        uint payoutWalletsCount = _payoutWallets.length;
        uint paymentPerWallet = address(this).balance / payoutWalletsCount;

        for (uint i = 0; i < payoutWalletsCount; i++) {
            payable(_payoutWallets[i]).transfer(paymentPerWallet);
        }
    }

    // Number of tokens minted by an address
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    // Check whether whitelist sales are already started
    function isHoldersClaimOn() public view returns (bool) {
        return block.timestamp >= CLAIM_START_TIME;
    }

    // Get the ownership for the specified tokenId
    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    // URI with contract metadata for opensea
    function contractURI() public pure returns (string memory) {
        return "ipfs://QmTFb7LFZT48jXKjUekJuQdhq9oZJkveSaTCP1THpthXjS";
    }

    // Starting index for the token IDs
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // Token metadata folder/root URI
    string private _baseTokenURI = "ipfs://QmcdTu5KJMiiXgzSWxXwvQ5nQwHGxWhvsxuwZdbmCHa87J/";

    // Get base token URI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Set base token URI
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // Recieve any amount of ether
    receive() external payable {}
}