// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/* 
    :::::::::      :::     :::::::::  
    :+:    :+:   :+: :+:   :+:    :+: 
    +:+    +:+  +:+   +:+  +:+    +:+ 
    +#++:++#:  +#++:++#++: +#+    +:+ 
    +#+    +#+ +#+     +#+ +#+    +#+ 
    #+#    #+# #+#     #+# #+#    #+# 
    ###    ### ###     ### #########  

    Malus Creations
    ---------------------------------------------
    Project: Project Radiance
    Artist: Omar Wael
    ---------------------------------------------
    Developed by ATOMICON.PRO (info@atomicon.pro)
*/

import "./ERC721A_v2.2.0.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";
import "./Math.sol";
import "./Ownable.sol";

contract ProjectRadiance is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    using Math for uint;

    // Ensures that other contracts can't call a method 
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    uint16 public collectionSize = 999;
    uint256 public saleTokenPrice = 0.09 ether;

    uint32 public holdersClaimStartTime = 1645632000;
    uint32 public saleStartTime = 1645718400;

    uint256 private _yetToPayToDeveloper = 2.0 ether;
    address private _creatorPayoutAddress = 0xAb8da4a15424E0A51B31317f3A69f76f1c4033c1;
    address private _developerPayoutAddress = 0x4E98bd082406e99A0405EdAAD0744CB2A1c4EeBA;

    bytes8 private _hashSalt = 0x6f7a555a58504f52;
    address private _signerAddress = 0x47C3CdBEA980199C677f8bbfa1AB3098C060CEC3;

    // Used nonces for minting signatures    
    mapping(uint64 => bool) private _usedNonces;

    constructor() ERC721A("Project Radiance by Omar Wael", "RAD") {}

    // Claim tokens for free based on a backend whitelist
    function claimMint(bytes32 hash, bytes memory signature, uint256 quantity, uint64 maxTokens, uint64 nonce)
        external
        callerIsUser
    {
        require(isHoldersClaimOn(), "Holders claim stage have not begun yet");
        require(!isSaleOn(), "Holders claim stage is already over");
        
        require(totalSupply() + quantity <= collectionSize, "Reached max supply");
        require(numberMinted(msg.sender) + quantity <= maxTokens, "Exceeding claiming limit for this account");

        require(_operationHash(msg.sender, quantity, maxTokens, nonce) == hash, "Hash comparison failed");
        require(_isTrustedSigner(hash, signature), "Direct minting is disallowed");
        require(!_usedNonces[nonce], "Hash is already used");
        
        _safeMint(msg.sender, quantity);
        _usedNonces[nonce] = true;
    }

    // Mint tokens during the sales
    function saleMint(bytes32 hash, bytes memory signature, uint256 quantity, uint64 nonce)
        external
        payable
        callerIsUser
    {
        require(isSaleOn(), "Sales have not begun yet");

        require(totalSupply() + quantity <= collectionSize, "Reached max supply");
        require(msg.value == (saleTokenPrice * quantity), "Invalid amount of ETH sent");

        require(_operationHash(msg.sender, quantity, 18446744073709551615, nonce) == hash, "Hash comparison failed");
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

        require(totalSupply() + totalCount <= collectionSize, "Reached max supply");

        for(uint64 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], tokensCount[i]);
        }
    }

    // Generate hash of current mint operation
    function _operationHash(address buyer, uint256 quantity, uint64 maxTokens, uint64 nonce) internal view returns (bytes32) {        
        uint8 saleStage;
        if(isSaleOn())
            saleStage = 2;
        else if(isHoldersClaimOn())        
            saleStage = 1;
        else 
            require(false, "Sales have not begun yet");

        return keccak256(abi.encodePacked(
            _hashSalt,
            buyer,
            uint64(block.chainid),
            uint64(saleStage),
            uint64(maxTokens),
            uint64(quantity),
            uint64(nonce)
        ));
    } 

    // Test whether a message was signed by a trusted address
    function _isTrustedSigner(bytes32 hash, bytes memory signature) internal view returns(bool) {
        return _signerAddress == ECDSA.recover(hash, signature);
    }

    // Withdraw money for developers and for creators (2% and 98%)
    function withdrawMoney() external onlyOwner nonReentrant {
        require(address(this).balance > 0, "No funds on the contract");

        if(_yetToPayToDeveloper > 0) {
            uint256 developerPayoutSum = Math.min(_yetToPayToDeveloper, address(this).balance);
            payable(_developerPayoutAddress).transfer(developerPayoutSum);
            _yetToPayToDeveloper = _yetToPayToDeveloper - developerPayoutSum;
        }

        if(address(this).balance > 0) {
            payable(_creatorPayoutAddress).transfer(address(this).balance);
        }
    }

    // Number of tokens minted by an address
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    // Change public sales start time in unix time format
    function setSaleStartTime(uint32 unixTime) public onlyOwner {
        saleStartTime = unixTime;
    }

    // Check whether public sales are already started
    function isSaleOn() public view returns (bool) {
        return block.timestamp >= saleStartTime;
    }

    // Change holders claiming session start time in unix time format
    function setHoldersClaimStartTime(uint32 unixTime) public onlyOwner {
        holdersClaimStartTime = unixTime;
    }

    // Check whether whitelist sales are already started
    function isHoldersClaimOn() public view returns (bool) {
        return block.timestamp >= holdersClaimStartTime;
    }

    // Change collection size limits
    function setCollectionSize(uint16 newSize) external onlyOwner {
        require(newSize >= totalSupply(), "Can't set collection size lower then total supply");
        collectionSize = newSize;
    }

    // Change sales token price
    function setSaleTokenPrice(uint256 newPriceInWei) external onlyOwner {
        saleTokenPrice = newPriceInWei;
    }

    // Get the ownership for the specified tokenId
    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    // URI with contract metadata for opensea
    function contractURI() public pure returns (string memory) {
        return "ipfs://QmP4ZPLGxBaBBh2ELZ2g3csNqqFcp5zFC7ufx1tjU1Fctj";
    }

    // Token metadata folder/root URI
    string private _baseTokenURI;

    // Get base token URI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Set base token URI
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
}