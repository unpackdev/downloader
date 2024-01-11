// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./INonFungibleFilmsCastAndCrewPassToken.sol";
import "./Address.sol"; 

contract NonFungibleFilmsCastAndCrewPassMinter is Ownable, ReentrancyGuard {

    // ======== Supply =========
    uint256 public maxTokens;
    uint256 public constant MAX_MINTS_PER_TRANSACTION = 1;

    // ======== Sale Status =========
    bool public whitelistSaleIsActive = false;
    bool public publicSaleIsActive = false;

    // ======== Claim Tracking =========
    mapping(address => uint256) public whitelistClaimed;

    // ======== Whitelist Validation =========
    bytes32 public whitelistMerkleRoot;

    // ======== External Storage Contract =========
    INonFungibleFilmsCastAndCrewPassToken public immutable token;

    // ======== Constructor =========
    constructor(address contractAddress,
                uint256 tokenSupply) {
        token = INonFungibleFilmsCastAndCrewPassToken(contractAddress);
        maxTokens = tokenSupply;
    }

    // ======== Modifier Checks =========
    modifier isWhitelistMerkleRootSet() {
        require(whitelistMerkleRoot != 0, "Whitelist merkle root not set!");
        _;
    }

    modifier isValidMerkleProof(address _address, bytes32[] calldata merkleProof, uint256 quantity) {
        require(
            MerkleProof.verify(
                merkleProof, 
                whitelistMerkleRoot, 
                keccak256(abi.encodePacked(keccak256(abi.encodePacked(_address, quantity)))
                )
            ), 
            "Address is not on whitelist!");
        _;
    }
    
    modifier isSupplyAvailable(uint256 numberOfTokens) {
        uint256 supply = token.tokenCount();
        require(supply + numberOfTokens <= maxTokens, "Exceeds max token supply!");
        _;
    }
    
    modifier isWhitelistSaleActive() {
        require(whitelistSaleIsActive, "Whitelist sale is not active!");
        require(!publicSaleIsActive, "Public sale is active!");
        _;
    }
    
    modifier isPublicSaleActive() {
        require(!whitelistSaleIsActive, "Whitelist sale is active!");
        require(publicSaleIsActive, "Public sale is not active!");
        _;
    }
    
    modifier isWhitelistSpotsRemaining(uint amount) {
        require(whitelistClaimed[msg.sender] < amount, "No more whitelist mints remaining!");
        _;
    }

    // ======== Mint Functions =========
    /// @notice Allows a whitelisted user to mint 
    /// @param merkleProof The merkle proof to check whitelist access
    /// @param requested The amount of tokens user wants to mint in this transaction
    /// @param quantityAllowed The amount of tokens user is able to mint, checks against the merkleroot
    function mintWhitelist(bytes32[] calldata merkleProof, uint requested, uint quantityAllowed) public
        isWhitelistSaleActive()
        isWhitelistMerkleRootSet()
        isValidMerkleProof(msg.sender, merkleProof, quantityAllowed) 
        isSupplyAvailable(requested) 
        isWhitelistSpotsRemaining(quantityAllowed)
        nonReentrant {            
            token.mint(requested, msg.sender);
            whitelistClaimed[msg.sender] += requested;
    }

    /// @notice Allows any user to mint one token per transaction
    function mint() public
        isPublicSaleActive()
        isSupplyAvailable(MAX_MINTS_PER_TRANSACTION) 
        nonReentrant {      
            require(msg.sender == tx.origin, "Mint: not allowed from contract");
            token.mint(MAX_MINTS_PER_TRANSACTION, msg.sender);
    }

    /// @notice Allows the dev team to mint tokens
    /// @param _to The address where minted tokens should be sent
    /// @param _reserveAmount the amount of tokens to mint
    function mintTeamTokens(address _to, uint256 _reserveAmount) public 
        onlyOwner 
        isSupplyAvailable(_reserveAmount) {
            token.mint(_reserveAmount, _to);
    }

    // ======== Whitelisting =========
    /// @notice Allows the dev team to set the merkle root used for whitelist
    /// @param merkleRoot The merkle root generated offchain
    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    /// @notice Function to check if a user is whitelisted
    /// @param _address The address to check
    /// @param  merkleProof The merkle proof generated offchain
    /// @param  quantityAllowed The number of tokens a user thinks they can mint
    function isWhitelisted(address _address, bytes32[] calldata merkleProof, uint quantityAllowed) external view
        isValidMerkleProof(_address, merkleProof, quantityAllowed) 
        returns (bool) {            
            return true;
    }

    /// @notice Function to check the number of tokens a user has minted
    /// @param _address The address to check
    function isWhitelistClaimed(address _address) external view returns (uint) {
        return whitelistClaimed[_address];
    }

    // ======== State Management =========
    /// @notice Function to flip sale status
    function flipWhitelistSaleStatus() public onlyOwner {
        whitelistSaleIsActive = !whitelistSaleIsActive;
    }

    function flipPublicSaleStatus() public onlyOwner {
        publicSaleIsActive = !publicSaleIsActive;
    }
 
    // ======== Token Supply Management=========
    /// @notice Function to adjust max token supply
    /// @param newMaxTokenSupply The new token supply
    function adjustTokenSupply(uint256 newMaxTokenSupply) external onlyOwner {
        require(newMaxTokenSupply >= token.tokenCount(), "New token supply must be greater than or equal to token count!");
        require(maxTokens > newMaxTokenSupply, "Max token supply can only be decreased!");
        maxTokens = newMaxTokenSupply;
    }
}
