// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Address.sol"; 
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./INonFungibleFilmsMintPassToken.sol";

contract NonFungibleFilmsMintPassMinter is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ======== Supply =========
    uint256 public constant MAX_MINTS_PER_TX = 10;
    uint256 public constant  MAX_MINTS_PER_ADDRESS = 30;
    uint256 public maxTokens;

    // ======== Cost =========
    uint256 public constant TOKEN_PRICE_ETH = 1 ether;
    
    // ======== Ape Coin Support =========
    uint256 public tokenPriceApeCoin;
    IERC20 public immutable tokenApeCoin;

    // ======== Sale Status =========
    bool public saleIsActive = false;
    bool public saleApeCoinIsActive = false;

    uint256 public immutable preSaleStart; // Whitelist start date/time
    uint256 public immutable publicSaleStart; // Public sale start  date/time

    // ======== Claim Tracking =========
    mapping(address => uint256) private addressToMintCount;
    mapping(address => uint256) public whitelistClaimed;

    // ======== Whitelist Validation =========
    bytes32 public whitelistMerkleRoot;

    // ======== External Storage Contract =========
    INonFungibleFilmsMintPassToken public immutable token;

    // ======== Fund Management =========
    address public withdrawalAddress = 0x6A0Ed405F8c106D64412574Ea6B23EFeADA12200;

    event TokenPriceApeCoinChanged(uint256 oldPrice, uint256 newPrice);

    // ======== Constructor =========
    constructor(address contractAddress,
                uint256 preSaleStartTimestamp,
                uint256 publicSaleStartTimestamp,
                uint256 tokenSupply,
                IERC20 _tokenApeCoin,
                uint256 _tokenPriceApeCoin) {
        token = INonFungibleFilmsMintPassToken(contractAddress);
        preSaleStart = preSaleStartTimestamp;
        publicSaleStart = publicSaleStartTimestamp;
        maxTokens = tokenSupply;
        tokenApeCoin = _tokenApeCoin;
        
        setTokenPriceApeCoin(_tokenPriceApeCoin);
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

    modifier isSaleStarted(uint256 saleStartTime) {
        require(block.timestamp >= saleStartTime, "Sale not started!");
        _;
    }

    modifier isMaxMintsPerWalletExceeded(uint amount) {
        require(addressToMintCount[msg.sender] + amount <= MAX_MINTS_PER_ADDRESS, "Exceeds max mint per address!");
        _;
    }

    function setTokenPriceApeCoin(uint256 _tokenPriceApeCoin) public onlyOwner {
      emit TokenPriceApeCoinChanged(tokenPriceApeCoin, _tokenPriceApeCoin);
      tokenPriceApeCoin = _tokenPriceApeCoin;
    }

    function transferFunds(uint256 qty) private {
        if(msg.value == qty * TOKEN_PRICE_ETH) { // pay with ETH
            (bool success, ) = payable(withdrawalAddress).call{value: qty * TOKEN_PRICE_ETH}("");
            require(success, "transfer failed");
        } else if(msg.value == 0) { // pay with purchase token
            require(saleApeCoinIsActive, "Ape coin sale is not active!");

            tokenApeCoin.safeTransferFrom(
              msg.sender,
              withdrawalAddress,
              qty * tokenPriceApeCoin
            );
        } else {
          revert("invalid payment option");
        }
    }

    // ======== Mint Functions =========
    /// @notice Allows a whitelisted user to mint 
    /// @param merkleProof The merkle proof to check whitelist access
    /// @param requested The amount of tokens user wants to mint in this transaction
    /// @param quantityAllowed The amount of tokens user is able to mint, checks against the merkleroot
    function mintWhitelist(bytes32[] calldata merkleProof, uint requested, uint quantityAllowed) public payable
        isSaleActive()
        isSaleStarted(preSaleStart)
        isWhitelistMerkleRootSet()
        isValidMerkleProof(msg.sender, merkleProof, quantityAllowed) 
        isSupplyAvailable(requested) 
        isMaxMintsPerWalletExceeded(requested)
        nonReentrant {
            require(whitelistClaimed[msg.sender] < quantityAllowed, "No more whitelist mints remaining!");
            
            transferFunds(requested);
            token.mint(requested, msg.sender);
            whitelistClaimed[msg.sender] += requested;
    }

    /// @notice Allows a user to mint 
    /// @param amount The amount of tokens to mint
    function mintPublic(uint amount) public payable 
        isSaleActive()
        isSaleStarted(publicSaleStart)
        isSupplyAvailable(amount) 
        isMaxMintsPerWalletExceeded(amount)
        nonReentrant  {
            require(msg.sender == tx.origin, "Mint: not allowed from contract");
            require(amount <= MAX_MINTS_PER_TX, "Exceeds max mint per tx!");

            transferFunds(amount);
            token.mint(amount, msg.sender);
            addressToMintCount[msg.sender] += amount;
    }

    /// @notice Allows owner to mint team tokens
    /// @param _to The address to send the minted tokens to
    /// @param _reserveAmount The amount of tokens to mint
    function mintTeamTokens(address _to, uint256 _reserveAmount) public 
        onlyOwner 
        isSupplyAvailable(_reserveAmount) {
            token.mint(_reserveAmount, _to);
    }

    // ======== Whitelisting =========
    /// @notice Set the whitelist merkleroot
    /// @param merkleRoot The merkleroot generated offchain
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

    /// @notice Function to check the number of whitelist tokens a user has minted
    /// @param _address The address to check
    function isWhitelistClaimed(address _address) external view returns (uint) {
        return whitelistClaimed[_address];
    }

    // ======== Utilities =========
    function mintCount(address _address) external view returns (uint) {
        return addressToMintCount[_address];
    }

    function isPreSaleActive() external view returns (bool) {
        return block.timestamp >= preSaleStart && block.timestamp < publicSaleStart && saleIsActive;
    }

    function isPublicSaleActive() external view returns (bool) {
        return block.timestamp >= publicSaleStart && saleIsActive;
    }

    // ======== State Management =========
    function flipSaleStatus() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipSaleApeCoinStatus() public onlyOwner {
        saleApeCoinIsActive = !saleApeCoinIsActive;
    }
 
    // ======== Withdraw =========
    function setWithdrawalAddress(address _newWithdrawalAddress) public onlyOwner {
        withdrawalAddress = _newWithdrawalAddress;
    }
}
