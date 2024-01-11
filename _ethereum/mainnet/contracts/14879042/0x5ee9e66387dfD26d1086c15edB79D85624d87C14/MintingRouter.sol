//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/*
 * ██████╗ ██████╗ ███████╗██╗    ██╗██╗███████╗███████╗
 * ██╔══██╗██╔══██╗██╔════╝██║    ██║██║██╔════╝██╔════╝
 * ██████╔╝██████╔╝█████╗  ██║ █╗ ██║██║█████╗  ███████╗
 * ██╔══██╗██╔══██╗██╔══╝  ██║███╗██║██║██╔══╝  ╚════██║
 * ██████╔╝██║  ██║███████╗╚███╔███╔╝██║███████╗███████║
 * ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚══╝╚══╝ ╚═╝╚══════╝╚══════╝
 */

// Imports
import "./EIP712Whitelisting.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./ReentrancyGuard.sol";

/// NFT Interface
interface INFT {
    function mint(address recipient, uint256 quantity) external;

    function areReservesMinted() external view returns (bool);

    function maxSupply() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

/**
 * @title The Minting Router contract.
 */
contract MintingRouter is Ownable, EIP712Whitelisting, ReentrancyGuard {
    // The available sale types.
    enum SaleRoundType {
        WHITELIST,
        PUBLIC
    }

    // The sale round details.
    struct SaleRound {
        // The type of the sale.
        SaleRoundType saleType;
        // The price of a token during the sale round.
        uint256 price;
        // The total number of tokens available for minting during the sale round.
        uint256 totalAmount;
        // The total number of tokens available for minting by a single wallet during the sale round.
        uint256 limitAmountPerWallet;
        // The maximum number of tokens available for minting per single transaction.
        uint256 maxAmountPerMint;
        // The flag that indicates if the sale round is enabled.
        bool enabled;
    }
    /// @notice Indicates that tokens are unlimited.
    uint256 public constant UNLIMITED_AMOUNT = 0;
    /// @notice The current sale round details.
    SaleRound public currentSaleRound;
    /// @notice The current sale round index.
    uint256 public currentSaleIndex;
    /// @notice The Brewies NFT contract.
    INFT private _nftContract;
    /// @notice The contract that allows to split funds between multiple accounts.
    PaymentSplitter public splitter;
    /// @notice The number of NFTs minted during a sale round.
    mapping(uint256 => uint256) private _mintedAmountPerRound;
    /// @notice The number of NFTs minted during a sale round per wallet.
    mapping(uint256 => mapping(address => uint256))
        private _mintedAmountPerAddress;

    /**
     * @notice The smart contract constructor that initializes the minting router.
     * @dev The sizes of payees and shares should be equal.
     * @param nftContract The NFT contract.
     * @param tokenName The name of the NFT token.
     * @param version The version of the project.
     * @param payees The addresses of the accounts between which the funds are split.
     * @param shares The percentages of funds received by addresses.
     */
    constructor(
        INFT nftContract,
        string memory tokenName,
        string memory version,
        address[] memory payees,
        uint256[] memory shares
    ) EIP712Whitelisting(tokenName, version) {
        // Initialize the variables.
        _nftContract = nftContract;
        splitter = new PaymentSplitter(payees, shares);
        // Set the initial dummy value for the current sale index.
        currentSaleIndex = type(uint256).max;
    }

    /**
     * @notice Validates sale rounds parameters.
     * @param totalAmount The total amount of NFTs available for the current sale round.
     * @param limitAmountPerWallet The total number of NFTs that can be minted by a single wallet during the sale round.
     * @param maxAmountPerMint The maximum number of tokens available for minting per single transaction.
     */
    modifier validateSaleRoundParams(
        bool isNewRound,
        uint256 totalAmount,
        uint256 limitAmountPerWallet,
        uint256 maxAmountPerMint
    ) {
        require(
            _totalTokensLeft() > 0 &&
            totalAmount <= _totalTokensLeft(),
            "INVALID_TOTAL_AMOUNT"
        );

        if (!isNewRound) {
            require(totalAmount >= _mintedAmountPerRound[currentSaleIndex], "INVALID_TOTAL_AMOUNT");
        }

        if (totalAmount != UNLIMITED_AMOUNT) {
            require(limitAmountPerWallet <= totalAmount,"INVALID_LIMIT_PER_WALLET");
            require(maxAmountPerMint <= totalAmount, "INVALID_MAX_PER_MINT");
        }

        if (limitAmountPerWallet != UNLIMITED_AMOUNT) {
            require(maxAmountPerMint <= limitAmountPerWallet, "INVALID_MAX_PER_MINT");
        }

        _;
    }

    /**
     * @notice Changes the addresses that receive payment shares.
     * @param payees The addresses of the accounts between which the funds are split.
     * @param shares The percentages of funds received by addresses.
     */
    function changePayees(address[] memory payees, uint256[] memory shares)
        external
        onlyOwner
    {
        splitter = new PaymentSplitter(payees, shares);
    }

    /**
     * @notice Changes the current sale details.
     * @param price The price of an NFT for the current sale round.
     * @param totalAmount The total amount of NFTs available for the current sale round.
     * @param limitAmountPerWallet The total number of NFTs that can be minted by a single wallet during the sale round.
     * @param maxAmountPerMint The maximum number of tokens available for minting per single transaction.
     */
    function changeSaleRoundParams(
        uint256 price,
        uint256 totalAmount,
        uint256 limitAmountPerWallet,
        uint256 maxAmountPerMint
    ) external onlyOwner validateSaleRoundParams(
        false,
        totalAmount,
        limitAmountPerWallet,
        maxAmountPerMint
    ) {
        currentSaleRound.price = price;
        currentSaleRound.totalAmount = totalAmount;
        currentSaleRound.limitAmountPerWallet = limitAmountPerWallet;
        currentSaleRound.maxAmountPerMint = maxAmountPerMint;
    }

    /**
     * @notice Creates a new sale round.
     * @dev Requires sales to be disabled and reserves to be minted.
     * @param saleType The type of the sale round (WHITELIST - 0, PUBLIC SALE - 1).
     * @param price The price of an NFT for the current sale round.
     * @param totalAmount The total amount of NFTs available for the current sale round.
     * @param limitAmountPerWallet The total number of NFTs that can be minted by a single wallet during the sale round.
     * @param maxAmountPerMint The maximum number of tokens available for minting per single transaction.
     */
    function createSaleRound(
        SaleRoundType saleType,
        uint256 price,
        uint256 totalAmount,
        uint256 limitAmountPerWallet,
        uint256 maxAmountPerMint
    ) external onlyOwner validateSaleRoundParams(
        true,
        totalAmount,
        limitAmountPerWallet,
        maxAmountPerMint
    ) {
         // Check if the sales are closed.
        require(
            currentSaleRound.enabled == false,
            "SALE_ROUND_IS_ENABLED"
        );

        // Check if the reserves are minted.
        bool reservesMinted = _nftContract.areReservesMinted();
        require(
            reservesMinted == true,
            "ALL_RESERVED_TOKENS_NOT_MINTED"
        );

        // Set new sale parameters.
        currentSaleRound.price = price;
        currentSaleRound.totalAmount = totalAmount;
        currentSaleRound.limitAmountPerWallet = limitAmountPerWallet;
        currentSaleRound.maxAmountPerMint = maxAmountPerMint;
        currentSaleRound.saleType = saleType;
        // Increment the sale round index.
        if (currentSaleIndex == type(uint256).max) {
            currentSaleIndex = 0;
        } else {
            currentSaleIndex += 1;
        }
    }

    /**
     * @notice Starts the sale round.
     */
    function enableSaleRound() external onlyOwner {
        require(currentSaleIndex != type(uint256).max, "NO_SALE_ROUND_CREATED");
        require(currentSaleRound.enabled == false, "SALE_ROUND_ENABLED_ALREADY");
        currentSaleRound.enabled = true;
    }

    /**
     * @notice Closes the sale round.
     */
    function disableSaleRound() external onlyOwner {
        require(currentSaleRound.enabled == true, "SALE_ROUND_DISABLED_ALREADY");
        currentSaleRound.enabled = false;
    }

    /**
     * @notice Mints NFTs during whitelist sale rounds.
     * @dev Requires the current sale round to be a WHITELIST round.
     * @param recipient The address that will receive the minted NFT.
     * @param quantity The number of NFTs to mint.
     * @param signature The signature of a whitelisted minter.
     */
    function whitelistMint(
        address recipient,
        uint256 quantity,
        bytes calldata signature
    ) external payable requiresWhitelist(signature) nonReentrant {
        require(
            currentSaleRound.saleType == SaleRoundType.WHITELIST && currentSaleRound.enabled,
            "WHITELIST_ROUND_NOT_ENABLED"
        );
        _mint(recipient, quantity);
    }

    /**
     * @notice Mints NFTs during public sale rounds.
     * @dev Requires the current sale round to be a PUBLIC round.
     * @param recipient The address that will receive the minted NFT.
     * @param quantity The number of NFTs to mint.
     */
    function publicMint(address recipient, uint256 quantity)
        external
        payable
        nonReentrant
    {
        require(
            currentSaleRound.saleType == SaleRoundType.PUBLIC && currentSaleRound.enabled,
            "PUBLIC_ROUND_NOT_ENABLED"
        );
        _mint(recipient, quantity);
    }

    /**
     * @notice Sets the address that is used during whitelist generation.
     * @param signer The address used during whitelist generation.
     */
    function setWhitelistSigningAddress(address signer) public onlyOwner {
        _setWhitelistSigningAddress(signer);
    }

    /**
     * @notice Releases the share to the specified account.
     * @dev The share of the address should be greater than 0.
     * @param account The address of the share receiver.
     */
    function release(address payable account) public onlyOwner {
        splitter.release(account);
    }

    /**
     * @notice Calculates the number of tokens a minter is allowed to mint.
     * @param minter The minter address.
     * @return The number of tokens that a minter can mint.
     */
    function allowedTokenCount(address minter) public view returns (uint256) {
        if (currentSaleRound.enabled == false) {
            return 0;
        }

        // Calculate the allowed number of tokens to mint by a wallet.
        uint256 allowedWalletCount = _totalTokensLeft();
        if (currentSaleRound.limitAmountPerWallet != UNLIMITED_AMOUNT) {
            allowedWalletCount = currentSaleRound.limitAmountPerWallet - _mintedAmountPerAddress[currentSaleIndex][minter];
        }

        // Calculate the limit of the number of tokens per single mint.
        uint256 allowedAmountPerMint = _totalTokensLeft();
        if (currentSaleRound.maxAmountPerMint != UNLIMITED_AMOUNT) {
            allowedAmountPerMint = currentSaleRound.maxAmountPerMint;
        }

        return _min(
            allowedAmountPerMint,
            _min(allowedWalletCount, tokensLeft())
        );
    }

    /**
     * @notice Returns the number of tokens left for the running sale round.
     */
    function tokensLeft() public view returns (uint256) {
        if (currentSaleRound.enabled == false) {
            return 0;
        }

        if (currentSaleRound.totalAmount == UNLIMITED_AMOUNT) {
            return _totalTokensLeft();
        }

        return currentSaleRound.totalAmount - _mintedAmountPerRound[currentSaleIndex];
    }

    /**
     * @notice Mints NFTs.
     * @param recipient The address that will receive the minted NFT.
     * @param quantity The number of NFTs to mint.
     */
    function _mint(
        address recipient,
        uint256 quantity
    ) private {
        require(quantity > 0, "ZERO_QUANTITY_NOT_ALLOWED");
        require(allowedTokenCount(recipient) >= quantity, "MAX_MINTS_EXCEEDED");
        require(msg.value >= currentSaleRound.price * quantity, "INSUFFICIENT_FUNDS");
        // Update the number of total tokens minted by the minter.
        _mintedAmountPerAddress[currentSaleIndex][recipient] += quantity;
        _mintedAmountPerRound[currentSaleIndex] += quantity;
        // Mint NFTs.
        _nftContract.mint(recipient, quantity);
        (bool sent, ) = payable(splitter).call{value: msg.value}("");
        require(sent, "FAIL_FUNDS_TRANSFER");
    }

    /**
     * @notice Returns the number of available tokens to mint left in the supply.
     * @return The number of available tokens to mint left in the supply.
     */
    function _totalTokensLeft() private view returns(uint256) {
        return _nftContract.maxSupply() - _nftContract.totalSupply();
    }

    /**
     * @notice Calculates a minimum of two values provided.
     * @return The minimum of two values.
     */
    function _min(uint256 a, uint256 b) private pure returns(uint256) {
        if (a < b) {
            return a;
        }

        return b;
    }
}
