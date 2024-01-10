// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";
import "./ERC721ABurnable.sol";

contract DogeAlliance is Ownable, ERC721A, ERC721ABurnable, ReentrancyGuard {

    string public baseURI; // url for the metadata
    uint256 public reserved = 100; 
    uint256 public constant price = 0.05 ether;
    uint256 public constant stealthpPice = 0.03 ether;
    uint8 public constant maxStealthPurchase = 3;
    uint8 public constant maxPublicPurchase = 5;
    uint256 public freeMintSupply = 50;
    uint256 public constant maxSupply = 9000;
    bool public isFreeActive = false;
    bool public isPublicActive = false;
    bool public isStealthActive = false;

    mapping (address => bool) public mintedFree;
    mapping(address => uint256) addressBlockBought;

    bytes32 private freeMerkleRoot;

    constructor(bytes32 freeRoot) ERC721A("Doge Alliance", "DOGE")  {
        freeMerkleRoot = freeRoot;
    }

    modifier secureMint(uint8 mintType) {
        require(addressBlockBought[msg.sender] < block.timestamp, "CANNOT_MINT_ON_THE_SAME_BLOCK");
        require(tx.origin == msg.sender,"CONTRACTS_NOT_ALLOWED_TO_MINT");

        if(mintType == 0) {
            require(isFreeActive, "FREE_MINT_IS_NOT_YET_ACTIVE");
        } 

        if(mintType == 1) {
            require(isStealthActive, "STEALTH_MINT_IS_NOT_YET_ACTIVE");
        } 

        if(mintType == 2) {
            require(isPublicActive, "PUBLIC_MINT_IS_NOT_YET_ACTIVE");
        }
        _;
    }

    /**
     * Mint Free
     */
    function freeMintDoge(bytes32[] calldata proof) external secureMint(0) {

        require(MerkleProof.verify(proof, freeMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "YOU_ARE_NOT_WHITELISTED_TO_MINT_FREE");
        require(!mintedFree[msg.sender], "ALREADY_MINTED_FREE");
        require(totalSupply() + 1 <= freeMintSupply, "EXCEEDS_FREE_MINT_SUPPLY" );
        addressBlockBought[msg.sender] = block.timestamp;
        mintedFree[msg.sender] = true;
        _safeMint( msg.sender, 1);
    }

    /**
     * Mint Stealth
     */
    function stealthMint(uint256 numberOfTokens) external payable secureMint(1) {
        require(numberOfTokens <= maxStealthPurchase, "CANNOT_MINT_MORE_THAN_3");
        require(msg.value == stealthpPice * numberOfTokens, "INSUFFICIENT_PAYMENT");
        require(totalSupply() + numberOfTokens <= maxSupply, "EXCEEDS_MAX_SUPPLY" );

        addressBlockBought[msg.sender] = block.timestamp;
        _safeMint(msg.sender, numberOfTokens);
    }

    /**
     * Mint Public
     */
    function publicMint(uint256 numberOfTokens) external payable secureMint(2) {
        require(msg.value == price * numberOfTokens, "INSUFFICIENT_PAYMENT");
        require(numberOfTokens <= maxPublicPurchase, "CANNOT_MINT_MORE_THAN_5");
        require(totalSupply() + numberOfTokens <= maxSupply, "EXCEEDS_MAX_SUPPLY" );

        addressBlockBought[msg.sender] = block.timestamp;
        _safeMint(msg.sender, numberOfTokens);
    }

    /**
     * reserve Doges for giveaways
     */
    function mintReserved(uint256 numberOfTokens) external onlyOwner {
        require(reserved > 0, "RESERVED_HAS_MINT_MINTED");
        require(numberOfTokens <= reserved, "EXCEEDS_MAX_MINT_FOR_TEAM");

        reserved -= reserved;
        _safeMint(msg.sender, numberOfTokens);
    }
    
    // /**
    //  * Returns Doges of the Caller
    //  */
    // function DogesOfOwner(address _owner) external view returns(uint256[] memory) {
    //     uint256 tokenCount = balanceOf(_owner);

    //     uint256[] memory tokensId = new uint256[](tokenCount);
    //     for(uint256 i; i < tokenCount; i++){
    //         tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    //     }
    //     return tokensId;
    // }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // setters

    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        freeMerkleRoot = merkleRoot;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setFreeMintSupply(uint256 _freeMintSupply) external onlyOwner {
        freeMintSupply = _freeMintSupply;
    }

    // toggles

    function toggleFreeActive() external onlyOwner {
        isFreeActive = !isFreeActive;
    }


    function togglePresaleActive() external onlyOwner {
        isStealthActive = !isStealthActive;
    }

    function toggleSaleActive() external onlyOwner {
        isPublicActive = !isPublicActive;
    }

    /**
     * Withdraw Ether
     **/
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Failed to withdraw payment");
    }
}