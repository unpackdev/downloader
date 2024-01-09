// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/* 
    (      (      (        (               *         )       )      )  
    )\ )   )\ )   )\ )     )\ )          (  `     ( /(    ( /(   ( /(  
    (()/(  (()/(  (()/(    (()/(    (     )\))(    )\())   )\())  )\()) 
    /(_))  /(_))  /(_))    /(_))   )\   ((_)()\  ((_)\   ((_)\  ((_)\  
    (_))   (_))   (_))     (_))_   ((_)  (_()((_)   ((_)   _((_)  _((_) 
    | |    |_ _|  | |       |   \  | __| |  \/  |  / _ \  | \| | |_  /  
    | |__   | |   | |__     | |) | | _|  | |\/| | | (_) | | .` |  / /   
    |____| |___|  |____|    |___/  |___| |_|  |_|  \___/  |_|\_| /___|  

    Lil Demonz All Rights Reserved 2022
    Developed by ATOMICON.PRO (info@atomicon.pro)
*/

import "./ERC721A.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";
import "./Math.sol";
import "./Ownable.sol";

contract LilDemonz is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    using Math for uint;

    // Ensures that other contracts can't call a method 
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    uint16 constant public COLLECTION_SIZE = 9999;
    uint256 constant public TOKEN_PRICE = 0.09 ether;
    
    uint8 constant public MAX_TOKENS_WHITELIST_SALE = 3;
    uint8 constant public MAX_TOKENS_PUBLIC_SALE = 2;

    uint32 public whitelistSaleStartTime = 1644768000;
    uint32 public publicSaleStartTime = 1644778800;

    uint256 private _yetToPayToDeveloper = 17.99 ether;
    address private _creatorPayoutAddress = 0x2364a6dC7b6A36002a5249Cb69e2534D569B6118;
    address private _developerPayoutAddress = 0x4E98bd082406e99A0405EdAAD0744CB2A1c4EeBA;

    bytes8 private _hashSalt = 0x59655436346a7037;
    address private _signerAddress = 0xF8595114806a464e18B7b3878d25D8B9DD46E824;

    // Ammount of tokens an address has minted during the whitelist sales
    mapping (address => uint256) private _numberMintedDuringWhitelistSale;

    // Used nonces for minting signatures    
    mapping(uint64 => bool) private _usedNonces;

    constructor() ERC721A("Lil Demonz", "DEMONZ") {}

    // Mint tokens during the sales
    function saleMint(bytes32 hash, bytes memory signature, uint64 nonce, uint256 quantity)
        external
        payable
        callerIsUser
    {
        require(totalSupply() + quantity <= COLLECTION_SIZE, "Reached max supply");
        require(msg.value == (TOKEN_PRICE * quantity), "Invalid amount of ETH sent");

        if(isPublicSaleOn())
            require(quantity <= numberAbleToMint(msg.sender), "Exceeding minting limit for this account");
        else if(isWhitelistSaleOn())
            require(quantity <= numberAbleToMint(msg.sender), "Exceeding minting limit for this account during whitelist sales");
        else
            require(false, "Sales have not begun yet");

        require(_operationHash(msg.sender, quantity, nonce) == hash, "Hash comparison failed");
        require(_isTrustedSigner(hash, signature), "Direct minting is disallowed");
        require(!_usedNonces[nonce], "Hash is already used");

        _safeMint(msg.sender, quantity);
        _usedNonces[nonce] = true;

        if(!isPublicSaleOn())
            _numberMintedDuringWhitelistSale[msg.sender] = _numberMintedDuringWhitelistSale[msg.sender] + quantity;
    }

    // Generate hash of current mint operation
    function _operationHash(address buyer, uint256 quantity, uint64 nonce) internal view returns (bytes32) {        
        uint8 saleStage;
        if(isPublicSaleOn())
            saleStage = 2;
        else if(isWhitelistSaleOn())        
            saleStage = 1;
        else 
            require(false, "Sales have not begun yet");

        return keccak256(abi.encodePacked(
            _hashSalt,
            buyer,
            uint64(block.chainid),
            uint64(saleStage),
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

    // Number of tokens an address can mint at the given moment
    function numberAbleToMint(address owner) public view returns (uint256) {
        if(isPublicSaleOn())
            return MAX_TOKENS_PUBLIC_SALE + numberMintedDuringWhitelistSale(owner) - numberMinted(owner);
        else if(isWhitelistSaleOn())
            return MAX_TOKENS_WHITELIST_SALE - numberMinted(owner);
        else
            return 0;
    }

    // Number of tokens minted by an address
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    // Number of tokens minted by an address during the whitelist sales
    function numberMintedDuringWhitelistSale(address owner) public view returns(uint256){
        return _numberMintedDuringWhitelistSale[owner];
    }

    // Change public sales start time in unix time format
    function setPublicSaleStartTime(uint32 unixTime) public onlyOwner {
        publicSaleStartTime = unixTime;
    }

    // Check whether public sales are already started
    function isPublicSaleOn() public view returns (bool) {
        return block.timestamp >= publicSaleStartTime;
    }

    // Change whitelist sales start time in unix time format
    function setWhitelistSaleStartTime(uint32 unixTime) public onlyOwner {
        whitelistSaleStartTime = unixTime;
    }

    // Check whether whitelist sales are already started
    function isWhitelistSaleOn() public view returns (bool) {
        return block.timestamp >= whitelistSaleStartTime;
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    // Token metadata folder/root URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
}