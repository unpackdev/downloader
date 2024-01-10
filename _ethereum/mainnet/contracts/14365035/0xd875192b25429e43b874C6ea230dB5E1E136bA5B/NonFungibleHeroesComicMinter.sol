// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./INonFungibleHeroesComicToken.sol";
import "./Address.sol"; 

contract NonFungibleHeroesComicMinter is Ownable, ReentrancyGuard {

    // ======== Supply =========
    uint256 public constant MAX_MINTS_PER_TX = 3;
    uint256 public maxTokens;

    // ======== Sale Status =========
    bool public saleIsActive = false;

    // ======== Current Token Issue =========    
    uint256 public currentIssue = 1; 
    mapping (uint256 => bool) public issues;

    // ======== Claim Tracking =========
    mapping(uint256 => mapping (address => uint256)) public whitelistClaimed;

    // ======== Whitelist Validation =========
    bytes32 public whitelistMerkleRoot;

    // ======== External Storage Contract =========
    INonFungibleHeroesComicToken public immutable token;

    // ======== Constructor =========
    constructor(address contractAddress,
                uint256 tokenSupply) {
        token = INonFungibleHeroesComicToken(contractAddress);
        maxTokens = tokenSupply;
        issues[currentIssue] = true;
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
    
    modifier isSaleActive() {
        require(saleIsActive, "Sale is not active!");
        _;
    }

    modifier isMaxMintsPerWalletExceeded(uint amount) {
        require(whitelistClaimed[currentIssue][msg.sender] + amount <= MAX_MINTS_PER_TX, "Exceeds max mint per tx!");
        _;
    }

    // ======== Mint Functions =========
    /// @notice Allows a whitelisted user to mint 
    /// @param merkleProof The merkle proof to check whitelist access
    /// @param requested The amount of tokens user wants to mint in this transaction
    /// @param quantityAllowed The amount of tokens user is able to mint, checks against the merkleroot
    function mintWhitelist(bytes32[] calldata merkleProof, uint requested, uint quantityAllowed) public
        isSaleActive()
        isWhitelistMerkleRootSet()
        isValidMerkleProof(msg.sender, merkleProof, quantityAllowed) 
        isSupplyAvailable(requested) 
        isMaxMintsPerWalletExceeded(requested)
        nonReentrant {
            require(whitelistClaimed[currentIssue][msg.sender] < quantityAllowed, "No more whitelist mints remaining!");
            token.mint(requested, msg.sender);
            whitelistClaimed[currentIssue][msg.sender] += requested;
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
        return whitelistClaimed[currentIssue][_address];
    }

    // ======== State Management =========
    /// @notice Function to flip sale status
    function flipSaleStatus() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
 
    // ======== Token Supply Management=========
    /// @notice Function to adjust max token supply
    /// @param newMaxTokenSupply The new token supply
    function adjustTokenSupply(uint256 newMaxTokenSupply) external onlyOwner {
        require(newMaxTokenSupply > token.tokenCount(), "New token supply must be greater than token count!");
        maxTokens = newMaxTokenSupply;
    }

    /// @notice Function to update the current series
    /// @param newCurrentIssue The new current series
    function updateCurrentIssue(uint256 newCurrentIssue) external onlyOwner {
        currentIssue = newCurrentIssue;
        if(!issues[newCurrentIssue]) {
            issues[newCurrentIssue] = true;
        }
    }
}
