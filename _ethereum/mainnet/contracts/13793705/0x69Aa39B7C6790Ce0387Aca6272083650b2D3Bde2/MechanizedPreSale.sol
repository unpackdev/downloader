// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

interface Mechanized {
    function doMint(uint256, address) external;
}

contract MechanizedPreSale is Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    using ECDSA for bytes32; 

    Mechanized public nft;

    // Addresses
    address public proxyRegistryAddress; // Opensea: the address of the Opensea ProxyRegistry 

    // Flags
    bool public preSaleIsActive = false;
    bool public ownerCanModify = true;

     // Token data
    uint256 public MAX_SUPPLY_PRE_SALE = 515;    // the maximum amount of tokens that can be minted
    uint256 public MAX_GIVEAWAY_SUPPLY = 34;
    uint256 public PRE_SALE_MINT_PRICE = 0.08 ether; //persale mint price: 0.01 ETH
    uint256 public MAX_PRE_MINT_PER_USER = 1; // maximum amount of tokens one address can mint  

    uint256 public preSaleMinted = 0;
    uint256 public giveAwayMinted = 0;

    // mappings
    mapping(address => uint256) public _preMintsPerAddress; // maps addresses to the amount of tokens they have minted
    mapping(address => uint256) public preSaleAddressToNonce; // maps whitelisted addresses to a nonce
    mapping(address => bool) public giveAwayClaimed;

     /** MERKLE */
    bytes32 public preSaleMerkleRoot = 0x5761c3c3b9ebfbcdaa2985db5a7af8ce4a68725653b2a65bbe356d6ba2525653;
    bytes32 public giveawayMerkleRoot = 0x756a500171ed49703e751478d934fb2e1d61613402c57c365e3d77ee5209058f;

    // events
    event ReceivedEther(uint256 amount, address _from);    

    // modifiers
    modifier modifiable {
        require(ownerCanModify, "NOT MODIFIABLE");
        _;
    }

    constructor(
        address _mechanized
    )  {
        nft = Mechanized(_mechanized);
    }    

    /** === ONLY OWNER === */

    /**
     * @dev function to change the max amount of 
     * tokens that can be minted
     *
     * @param _maxSupply the new max tokens that can be minted
     */
    function setMaxSupplyPreSale(uint256 _maxSupply) external onlyOwner modifiable {
        MAX_SUPPLY_PRE_SALE = _maxSupply;
    }

    /**
     * @dev function to change the max amount of 
     * tokens that an address can mint
     *
     * @param _maxPurchase the new max tokens that an address can mint
     */
    function setMaxPreMintPerUser(uint256 _maxPurchase) external onlyOwner modifiable {
        MAX_PRE_MINT_PER_USER = _maxPurchase;
    }

    /**
     * @dev function to change the presale mint price of a token
     *
     * @param _mintPrice the new mint price of a single token
     */
    function setPreSaleMintPrice(uint256 _mintPrice) external onlyOwner modifiable {
        PRE_SALE_MINT_PRICE = _mintPrice;
    }

    function setPreMintMerkleRoot(bytes32 _root) external onlyOwner modifiable {
        preSaleMerkleRoot = _root;
    }

    function setGiveawayMerkleRoot(bytes32 _root) external onlyOwner modifiable {
        giveawayMerkleRoot = _root;
    }

    /**
     * @dev Allows the owner to withdraw ether
     */
    function withdrawEth() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "ETH Transfer failed");
    }

    /**
     * @dev Pause presale if active, make active if paused
    */
    function flipPreSaleState() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }


    function disableModifications() external onlyOwner {
        ownerCanModify = false;
    }

    /** === MINT METHODS === */
    /**
    * @dev Mints a token to an address with a tokenURI.
    * @param numberOfTokens the number of tokens to mint
    */
    function preSaleMint(uint256 numberOfTokens, bytes32[] calldata proof) external payable {
        require(preSaleIsActive, "SALE NOT ACTIVE");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, preSaleMerkleRoot, leaf), "INVALID PROOF");
        
        require(_preMintsPerAddress[msg.sender].add(numberOfTokens) <= MAX_PRE_MINT_PER_USER, "MINTER EXCEEDS MAX TOKENS");
        require(preSaleMinted.add(numberOfTokens) <= MAX_SUPPLY_PRE_SALE, "MAX TOKENS ALREADY MINTED");
        require(PRE_SALE_MINT_PRICE.mul(numberOfTokens) == msg.value, "ETHER SENT NOT CORRECT");         
        
        preSaleMinted = preSaleMinted.add(numberOfTokens);
        _preMintsPerAddress[msg.sender] = _preMintsPerAddress[msg.sender].add(numberOfTokens);
        nft.doMint(numberOfTokens, msg.sender);
    }

    /**
    * @dev Mints a token to an address with a tokenURI.
    * @param numberOfTokens the number of tokens to mint
    */
    function claimGiveAway(uint256 numberOfTokens, bytes32[] calldata proof) external payable {
        require(!giveAwayClaimed[msg.sender], "GIVEAWAY ALREADY CLAIMED");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, numberOfTokens));
        require(MerkleProof.verify(proof, giveawayMerkleRoot, leaf), "INVALID PROOF");

        require(giveAwayMinted.add(numberOfTokens) <= MAX_GIVEAWAY_SUPPLY, "MAX AMOUNT MINTED");
        giveAwayMinted = giveAwayMinted.add(numberOfTokens);
        giveAwayClaimed[msg.sender] = true;
        nft.doMint(numberOfTokens, msg.sender);
    }

    /** === MISC === */
    
    /**
     * @dev Fallback function for receiving Ether
     */
    receive() external payable {
        emit ReceivedEther(msg.value, msg.sender);
    }        
}