// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Address.sol"; 
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IToken.sol";

contract Minter is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ======== Supply =========
    uint256 public maxMintsPerAddress;
    uint256 public maxTokens;

    // ======== Cost =========;
    uint256 public immutable tokenPriceETH;
    uint256 public tokenPriceETH_Discount;
    uint256 public tokenPriceApeCoin;
    uint256 public tokenPriceApeCoin_Discount;
    
    event TokenPriceApeCoinChanged(uint256 oldPrice, uint256 newPrice);
    event TokenPriceApeCoinDiscountChanged(uint256 oldPrice, uint256 newPrice);
    event TokenPriceETHDiscountChanged(uint256 oldPrice, uint256 newPrice);

    // ======== Sale Status =========
    bool public saleIsActive = false;
    bool public saleApeCoinIsActive = false;
    bool public isWhitelistSaleActive = false;
    bool public isDiscountedSaleActive = false;
    bool public isPublicSaleActive = false;

    // ======== Claim Tracking =========
    mapping(address => uint256) private addressToMintCount;
    mapping(address => bool) public whitelistClaimed;
    mapping(address => uint256) public discountClaimed;

    // ======== Whitelist Validation =========
    bytes32 public whitelistMerkleRoot;
    bytes32 public discountMerkleRoot;

    // ======== External Storage Contract =========
    IToken public immutable token;

    // ======== Fund Management =========
    // NFF Gnosis Wallet
    address public withdrawalAddress = 0xAEE6a9660878A217f4070181FFb271c4De61fBac;

    // ======== ApeCoin Support =========
    IERC20 public immutable tokenApeCoin;

    // ======== Constructor =========
    constructor(address contractAddress,
                uint256 _maxTokens,
                uint256 _maxMintsPerAddress,
                IERC20 _tokenApeCoin,
                uint256 _tokenPriceETH_Discount,
                uint256 _tokenPriceETH,
                uint256 _tokenPriceApeCoin_Discount,
                uint256 _tokenPriceApeCoin) {
        token = IToken(contractAddress);
        maxTokens = _maxTokens;
        maxMintsPerAddress = _maxMintsPerAddress;
        tokenApeCoin = _tokenApeCoin;
        tokenPriceETH = _tokenPriceETH;

        setTokenPriceETHDiscount(_tokenPriceETH_Discount);
        setTokenPriceApeCoin(_tokenPriceApeCoin);
        setTokenPriceApeCoinDiscount(_tokenPriceApeCoin_Discount);
    }

    // ======== Modifier Checks =========
    modifier isWhitelistMerkleRootSet() {
        require(whitelistMerkleRoot != 0, "Whitelist merkle root not set!");
        _;
    }

    modifier isValidMerkleProofWhitelist(address _address, bytes32[] calldata merkleProof, uint256 quantity) {
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

    modifier isDiscountMerkleRootSet() {
        require(discountMerkleRoot != 0, "Discount merkle root not set!");
        _;
    }

    modifier isValidMerkleProofDiscount(address _address, bytes32[] calldata merkleProof, uint256 quantity) {
        require(
            MerkleProof.verify(
                merkleProof, 
                discountMerkleRoot, 
                keccak256(abi.encodePacked(keccak256(abi.encodePacked(_address, quantity)))
                )
            ), 
            "Address is not on discount list!");
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

    modifier isMaxMintsPerAddressExceeded(uint amount) {
        require(addressToMintCount[msg.sender] + amount <= maxMintsPerAddress, "Exceeds max mint per address!");
        _;
    }


    /// @notice Set the discounted token price in ETH
    /// @param _tokenPriceETHDiscount The ETH price
    function setTokenPriceETHDiscount(uint256 _tokenPriceETHDiscount) public onlyOwner {
      emit TokenPriceETHDiscountChanged(tokenPriceETH_Discount, _tokenPriceETHDiscount);
      tokenPriceETH_Discount = _tokenPriceETHDiscount;
    }

    /// @notice Set the token price in ApeCoin
    /// @param _tokenPriceApeCoin The ApeCoin price
    function setTokenPriceApeCoin(uint256 _tokenPriceApeCoin) public onlyOwner {
      emit TokenPriceApeCoinChanged(tokenPriceApeCoin, _tokenPriceApeCoin);
      tokenPriceApeCoin = _tokenPriceApeCoin;
    }

    /// @notice Set the discounted token price in ApeCoin
    /// @param _tokenPriceApeCoinDiscount The ApeCoin price
    function setTokenPriceApeCoinDiscount(uint256 _tokenPriceApeCoinDiscount) public onlyOwner {
      emit TokenPriceApeCoinDiscountChanged(tokenPriceApeCoin_Discount, _tokenPriceApeCoinDiscount);
      tokenPriceApeCoin_Discount = _tokenPriceApeCoinDiscount;
    }

    /// @notice Transfer funds to gnosis wallet
    /// @param qty The qty user is purchsing
    /// @param applyDiscount Is this a discounted purchase
    function transferFunds(uint256 qty, bool applyDiscount) private {

        uint256 priceETH = !applyDiscount ? tokenPriceETH : tokenPriceETH_Discount;
        uint256 priceApeCoin = !applyDiscount ? tokenPriceApeCoin : tokenPriceApeCoin_Discount;

        if(msg.value == qty * priceETH) { 
            // pay with ETH
            (bool success, ) = payable(withdrawalAddress).call{value: qty * priceETH}("");
            require(success, "transfer failed");
        } else if(msg.value == 0) { 
            // pay with ApeCoin
            require(saleApeCoinIsActive, "ApeCoin sale is not active!");

            tokenApeCoin.safeTransferFrom(
              msg.sender,
              withdrawalAddress,
              qty * priceApeCoin
            );
        } else {
          revert("invalid payment option");
        }
    }

    // ======== Mint Functions =========
    /// @notice Mint all available tokens on whitelist
    /// @param merkleProof The merkle proof generated offchain
    /// @param amount The amount user can mint
    function mintWhitelist(bytes32[] calldata merkleProof, uint amount) public 
        isSaleActive()
        isWhitelistMerkleRootSet()
        isValidMerkleProofWhitelist(msg.sender, merkleProof, amount) 
        isSupplyAvailable(amount) 
        isMaxMintsPerAddressExceeded(amount)
        nonReentrant {
            require(isWhitelistSaleActive, "Whitlist sale is not active!");
            require(!whitelistClaimed[msg.sender], "Whitelist is already claimed by this wallet!");

            token.mint(amount, msg.sender);

            addressToMintCount[msg.sender] += amount;

            whitelistClaimed[msg.sender] = true;
    }

    /// @notice Mint tokens at a discounted price
    /// @param merkleProof The merkle proof generated offchain
    /// @param amount The amount user can mint
    /// @param quantity The quantity user would like to mint
    function mintDiscount(bytes32[] calldata merkleProof, uint amount, uint quantity) public payable 
        isSaleActive()
        isDiscountMerkleRootSet()
        isValidMerkleProofDiscount(msg.sender, merkleProof, amount) 
        isSupplyAvailable(quantity) 
        isMaxMintsPerAddressExceeded(quantity)
        nonReentrant {
            require(isDiscountedSaleActive, "Discount sale is not active!");
            require(discountClaimed[msg.sender] != amount, "Discount is already claimed by this wallet!");

            token.mint(quantity, msg.sender);

            transferFunds(quantity, true);

            addressToMintCount[msg.sender] += quantity;
            discountClaimed[msg.sender]  += quantity;
    }


    /// @notice Mint tokens at public price
    /// @param quantity The quantity user would like to mint
    function mintPublic(uint quantity) public payable 
        isSaleActive()
        isSupplyAvailable(quantity) 
        isMaxMintsPerAddressExceeded(quantity)
        nonReentrant  {
            require(isPublicSaleActive, "Public sale is not active!");
            require(msg.sender == tx.origin, "Mint: not allowed from contract");

            transferFunds(quantity, false);

            token.mint(quantity, msg.sender);

            addressToMintCount[msg.sender] += quantity;
    }

    /// @notice Mint team tokens at zero cost
    /// @param _to The address to send the tokens
    /// @param _reserveAmount The quantity user would like to mint
    function mintTeamTokens(address _to, uint256 _reserveAmount) public 
        onlyOwner 
        isSupplyAvailable(_reserveAmount) {
            token.mint(_reserveAmount, _to);
    }

    // ======== Whitelisting =========
    /// @notice Set merkle root for whitelist mints
    /// @param merkleRoot The merkle root
    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    /// @notice Check if user is whitelisted
    /// @param _address The whitelisted address
    /// @param merkleProof The merkle proof generated offchain
    /// @param amount The number of tokens the user has been whitelisted for
    function isWhitelisted(address _address, bytes32[] calldata merkleProof, uint256 amount) external view
        isValidMerkleProofWhitelist(_address, merkleProof, amount) 
        returns (bool) {            
            require(!whitelistClaimed[_address], "Whitelist is already claimed by this wallet");

            return true;
    }

    /// @notice Check if user has claimed all their whitelist spots
    /// @param _address The whitelisted address
    function isWhitelistClaimed(address _address) external view returns (bool) {
        return whitelistClaimed[_address];
    }


    // ======== Discounting =========
    /// @notice Set merkle root for discounted mints
    /// @param merkleRoot The merkle root
    function setDiscountMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        discountMerkleRoot = merkleRoot;
    }

    /// @notice Check if user is on discount list
    /// @param _address The discounted address
    /// @param merkleProof The merkle proof generated offchain
    /// @param amount The number of tokens the user has been whitelisted for
    function isDiscounted(address _address, bytes32[] calldata merkleProof, uint256 amount) external view
        isValidMerkleProofDiscount(_address, merkleProof, amount) 
        returns (bool) {            
            require(discountClaimed[_address] != amount, "Discount is already claimed by this wallet");

            return true;
    }

    /// @notice Returns the number of discounted spots user has claimed
    /// @param _address The discounted address
    function discountsClaimed(address _address) external view returns (uint256) {
        return discountClaimed[_address];
    }

    // ======== Utilities =========
    /// @notice Returns the number of tokens minted by an address
    /// @param _address The minter's address
    function mintCount(address _address) external view returns (uint) {
        return addressToMintCount[_address];
    }

    // ======== State Management =========
    /// @notice Toggle mint sale status
    function flipSaleStatus() public onlyOwner {
        saleIsActive = !saleIsActive;
    } 

    /// @notice Toggle whitelist mint sale status
    function flipWhitelistSaleStatus() public onlyOwner {
        isWhitelistSaleActive = !isWhitelistSaleActive;
    } 

    /// @notice Toggle discounted mint sale status
    function flipDiscountedSaleStatus() public onlyOwner {
        isDiscountedSaleActive = !isDiscountedSaleActive;
    }

    /// @notice Toggle public mint sale status
    function flipPublicSaleStatus() public onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    } 

    /// @notice Toggle ApeCoin sale status
    function flipSaleApeCoinStatus() public onlyOwner {
        saleApeCoinIsActive = !saleApeCoinIsActive;
    }

    // ======== Token Supply Management=========
    /// @notice Set the max mints per address
    /// @param _max The maximum number of tokens a user can mint
    function setMaxMintPerAddress(uint _max) public onlyOwner {
        maxMintsPerAddress = _max;
    }

    /// @notice Set the max supply, can only be lowered not increased
    /// @param newMaxTokenSupply The maximum number of tokens that can be minted
    function decreaseTokenSupply(uint256 newMaxTokenSupply) external onlyOwner {
        require(maxTokens > newMaxTokenSupply, "Max token supply can only be decreased!");
        maxTokens = newMaxTokenSupply;
    }

    // ======== Withdraw =========
    /// @notice Set the withdrawal address for all funds
    /// @param _newWithdrawalAddress The withdrawal address for buth ETH/ApeCoin funds
    function setWithdrawalAddress(address _newWithdrawalAddress) public onlyOwner {
        withdrawalAddress = _newWithdrawalAddress;
    }
}
