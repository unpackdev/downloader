/*

888b     d888  .d88888b.   .d88888b.  888b    888          888      d8b                   
8888b   d8888 d88P" "Y88b d88P" "Y88b 8888b   888          888      Y8P                   
88888b.d88888 888     888 888     888 88888b  888          888                            
888Y88888P888 888     888 888     888 888Y88b 888  8888b.  888      888 .d8888b   8888b.  
888 Y888P 888 888     888 888     888 888 Y88b888     "88b 888      888 88K          "88b 
888  Y8P  888 888     888 888     888 888  Y88888 .d888888 888      888 "Y8888b. .d888888 
888   "   888 Y88b. .d88P Y88b. .d88P 888   Y8888 888  888 888      888      X88 888  888 
888       888  "Y88888P"   "Y88888P"  888    Y888 "Y888888 88888888 888  88888P' "Y888888 

*/

/**
 * @title  Smart Contract for the MOONaLisa Project
 * @author SteelBalls
 * @notice NFT Minting
 */

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./PaymentSplitter.sol";
import "./MerkleProof.sol";

// NFT minting contract with gas optimisation v1.0
contract MOONaLisa is ERC721, PaymentSplitter, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    // Variables
    uint256 public maxTokens = 7777;                              // Total token supply
    uint256 public tokenPrice = 50000000000000000;                // 0.05 ETH Token price
    bool public publicMintActive = false;
    uint256 public maxTokenPurchase = 20;                         // Maximum number of tokens that can be purchased in a single transaction
    uint256 public tokenReserve = 150;                            // Reserved up front for the teams effort and for giveaways/promotional activity
    bool public initialMintActive = false;
    uint256 public constant initialMintMax = 1;                   // Maximum number of tokens that can be purchased for initial mint
    uint256 public constant initialMintPrice = 0;                 // Initial mint price
    bool public presaleMintActive = false;
    uint256 public constant presaleMintMax = 5;                   // Maximum number of tokens that can be purchased for presale mint
    uint256 public constant presaleMintPrice = 25000000000000000; // Presale mint price
    bool public collectionIsRevealed = false;
    string public baseTokenURI;

    /* Merkle Tree Root
        The root hash of the Merkle Tree previously generated from our JS code. Remember to
        provide this as a bytes32 type and not a string. Should be prefixed with 0x.
    */
    bytes32 public merkleRoot;
    // Record whitelist addresses that have claimed
    mapping(address => bool) public initialMintClaimed; 
    mapping(address => bool) public presaleMintClaimed;
    
    // Withdraw Addresses
    address[] private teamWallets = [
        0x93a6000a9be2Ed80Eec33b57AC9a413e10a74d2b, // Project
        0x918638b3cc1813778333700e6f8eAcD9834555E9, // Founder
        0xd38eF170FcB60EE0FE7478DE0C9f2b2cCF3Ab574, // Partner
        0xBc2b466BC6BBdAdA9f0dcd2846ef25852EB1ABDc  // Partner
    ];

    uint256[] private teamShares = [1000, 4500, 4375, 125];

    // Constructor
    constructor()
        PaymentSplitter(teamWallets, teamShares)
        ERC721("MOONaLisa", "LISAS")
    {}

    /*
       @dev   Public mint
       @param _numberOfTokens Quantity to mint
    */
    function publicMint(uint _numberOfTokens) external payable {
        require(publicMintActive, "SALE_NOT_ACTIVE");
        require(_numberOfTokens > 0 && _numberOfTokens <= maxTokenPurchase, "MAX_TOKENS_EXCEEDED");
        require(_tokenSupply.current() <= maxTokens, "MAX_SUPPLY_EXCEEDED");
        require(msg.value >= tokenPrice * _numberOfTokens, "NOT_ENOUGH_ETHER");
        
        uint _mintIndex;
        for(uint i = 0; i < _numberOfTokens; i++) {
            _mintIndex = _tokenSupply.current();
            if (_mintIndex < maxTokens) {
                _safeMint(msg.sender, _mintIndex);
                _tokenSupply.increment();
            }
        }
    }

    /*
       @dev   Initial Whitelist mint
       @param _numberOfTokens Quantity to mint
       @param _merkleProof Root merkle proof to submit
    */
    function initialWhitelistMint(uint256 _numberOfTokens, bytes32[] calldata _merkleProof) external payable {
        require(initialMintActive, "SALE_NOT_ACTIVE");
        require(!initialMintClaimed[msg.sender], "ALREADY_CLAIMED");

        // Verify the provided _merkleProof, given to us through the API on the website
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "INVALID_PROOF");
        require(_numberOfTokens > 0 && _numberOfTokens <= initialMintMax, "MAX_TOKENS_EXCEEDED");
        require(_tokenSupply.current() + _numberOfTokens <= maxTokens, "MAX_SUPPLY_REACHED");
        require(msg.value >= initialMintPrice * _numberOfTokens, "NOT_ENOUGH_ETHER");

        uint _mintIndex;
        for(uint i = 0; i < _numberOfTokens; i++) {
            _mintIndex = _tokenSupply.current();
            if (_mintIndex < maxTokens) {
                _safeMint(msg.sender, _mintIndex);
                _tokenSupply.increment();
            }
        }

        //set address as having claimed their token
        initialMintClaimed[msg.sender] = true;
    }

    /*
       @dev   Presale Whitelist mint
       @param _numberOfTokens Quantity to mint
       @param _merkleProof Root merkle proof to submit
    */
    function presaleWhitelistMint(uint256 _numberOfTokens, bytes32[] calldata _merkleProof) external payable {
        require(presaleMintActive, "SALE_NOT_ACTIVE");
        require(!presaleMintClaimed[msg.sender], "ALREADY_CLAIMED");

        // Verify the provided _merkleProof, given to us through the API on the website
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "INVALID_PROOF");
        require(_numberOfTokens > 0 && _numberOfTokens <= presaleMintMax, "MAX_TOKENS_EXCEEDED");
        require(_tokenSupply.current() + _numberOfTokens <= maxTokens, "MAX_SUPPLY_REACHED");
        require(msg.value >= presaleMintPrice * _numberOfTokens, "NOT_ENOUGH_ETHER");

        uint _mintIndex;
        for(uint i = 0; i < _numberOfTokens; i++) {
            _mintIndex = _tokenSupply.current();
            if (_mintIndex < maxTokens) {
                _safeMint(msg.sender, _mintIndex);
                _tokenSupply.increment();
            }
        }

        //set address as having claimed their token
        presaleMintClaimed[msg.sender] = true;
    }

    // Reserve tokens for team, promotions and giveaways
    function reserveTokens(address _to, uint256 _reserveAmount) external onlyOwner {        
        uint mintIndex;
        require(_reserveAmount > 0 && _reserveAmount <= tokenReserve, "Not enough reserve left for team");
        for (uint i = 0; i < _reserveAmount; i++) {
            mintIndex = _tokenSupply.current();
            _safeMint(_to, mintIndex);
            _tokenSupply.increment();
        }
        tokenReserve -= _reserveAmount;
    }

    // How many NFTs are left?
    function remainingSupply() external view returns (uint256) {
        return maxTokens - _tokenSupply.current();
    }

    // How many NFTs are minted?
    function totalSupply() public view returns (uint256) {
        return _tokenSupply.current();
    }

    // Return baseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // Set baseURI
    function setBaseURI(string memory baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    // Toggle collection revealed
    function toggleCollectionRevealed() external onlyOwner {
        collectionIsRevealed = !collectionIsRevealed;
    }

    // Toggle sale active
    function togglePublicMint() external onlyOwner {
        publicMintActive = !publicMintActive;
    }

    // Toggle initial whitelist minting active
    function toggleInitialMint() external onlyOwner {
        initialMintActive = !initialMintActive;
    }

    // Toggle whitelist minting active
    function togglePresaleMint() external onlyOwner {
        presaleMintActive = !presaleMintActive;
    }

    // In case we need to update the reserved token value
    function setMaxTokenPurchase(uint256 newMaxTokenPurchase) external onlyOwner {
        maxTokenPurchase = newMaxTokenPurchase;
    }

    // In case we need to update the reserved token value
    function setTokenReserve(uint256 newTokenReserve) external onlyOwner {
        tokenReserve = newTokenReserve;
    }

    // In case supply needs to be updated
    function setMaxTokens(uint256 newMaxTokens) external onlyOwner {
        maxTokens = newMaxTokens;
    }

    // Just in case ETH does something silly
    function setTokenPrice(uint256 newPrice) external onlyOwner {
        tokenPrice = newPrice;
    }

    // You had to expect this function, right?
    function withdrawBalance() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Withdraw balance to wallets per share allocation
    function withdrawShares() external onlyOwner {
        for (uint256 i = 0; i < teamWallets.length; i++) {
            address payable wallet = payable(teamWallets[i]);
            release(wallet);
        }
    }

    // Set the merkle root
    function setMerkleRoot(bytes32 _merkleRootValue) external onlyOwner returns (bytes32) {
        merkleRoot = _merkleRootValue;
        return merkleRoot;
    }

}