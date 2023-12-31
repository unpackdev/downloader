pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: XriesSale.sol


pragma solidity ^0.8.0;



contract XeriesTokenSale is Ownable {
    address payable public platformWallet;
    IERC20 public token;
    IERC20 public usdtAddress;
    uint256 public tokenPriceInUSDT;
    uint256 public tokenPriceInETH;
    uint256 public totalSupply;
    uint256 public saleSupply;

    event TokensPurchased(address indexed buyer, uint256 amount, uint256 totalPriceInUSDT, uint256 totalPriceInETH);

    constructor(address _tokenAddress, uint256 _amount) {
        token = IERC20(_tokenAddress);
        platformWallet = payable(msg.sender); // Platform wallet is initially set to the contract deployer
        usdtAddress = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7); // TESTNET USDT ADDRESS
        token.transferFrom(msg.sender,address(this), (_amount * 1e3));

    }

    // Only the owner can set the token price in USDT and ETH
    function setTokenPrice(uint256 _priceInUSDT, uint256 _priceInETH) external onlyOwner {
        tokenPriceInUSDT = _priceInUSDT;
        tokenPriceInETH = _priceInETH;
    }

    // Only the owner can set the platform wallet address
    function setPlatformWallet(address payable _platformWallet) external onlyOwner {
        platformWallet = _platformWallet;
    }

    // Only the owner can set the ERC20 token address
    function setTokenAddress(address _tokenAddress) external onlyOwner {
        token = IERC20(_tokenAddress);
    }

    // Only the owner can set the ERC20 token address
    function setUsdtAddress(address _usdtAddress) external onlyOwner {
        usdtAddress = IERC20(_usdtAddress);
    }

    function withdrawTokens(uint256 _amount, address _tokenAddress) public onlyOwner returns (bool) {
        IERC20 tokenAddress = IERC20(_tokenAddress);
        tokenAddress.transfer(msg.sender, _amount);
        return true;
    }
    // Get the current token price in USDT and ETH
    function getTokenPrice() external view returns (uint256, uint256) {
        return (tokenPriceInUSDT, tokenPriceInETH);
    }

    // Get the remaining supply of tokens available for sale
    function getRemainingSupply() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    // Get the sale supply (tokens which were allowed to sell)
    function getSaleSupply() external view returns (uint256) {
        return saleSupply;
    }

   // Get the sale supply (tokens which were allowed to sell)
    function calculateTokensUSDT(uint256 _amountInUSDT) public view returns (uint256) {
       return ((_amountInUSDT * 1e3) * tokenPriceInUSDT) / 1e6; // Calculate token amount based on USDT price
    }

    // Get the sale supply (tokens which were allowed to sell)
    function calculateTokensEth(uint256 _amountInEth) public view returns (uint256) {
        return ((_amountInEth * 1e3) * tokenPriceInETH) / 1e18; // Calculate token amount based on USDT price
    }

    // Purchase tokens using USDT
    function purchaseWithUSDT(uint256 _amountInUSDT) external {
        require(_amountInUSDT > 0, "Amount must be greater than zero");
        require(tokenPriceInUSDT > 0, "Token price must be set");

        // Convert the USDT amount to the base unit (without decimals)
        uint256 tokenAmount = calculateTokensUSDT(_amountInUSDT);

        require(tokenAmount <= token.balanceOf(address(this)), "Not enough tokens available for sale");
        
        usdtAddress.transferFrom(msg.sender, platformWallet, _amountInUSDT);

        // Transfer tokens to the buyer
        token.transfer(msg.sender, tokenAmount );

        saleSupply += tokenAmount;

        emit TokensPurchased(msg.sender, tokenAmount, _amountInUSDT, 0);
    }

    // Fallback function to allow the contract to accept ETH
    receive() external payable {
        purchaseWithETH();
    }

    // Purchase tokens using ETH
    function purchaseWithETH() public payable {
        require(msg.value > 0, "ETH amount must be greater than zero");
        require(tokenPriceInETH > 0, "Token price must be set");

        // Convert the ETH amount to the base unit (without decimals)
        uint256 tokenAmount =  calculateTokensEth(msg.value);// Calculate token amount based on ETH price

        require(tokenAmount <= token.balanceOf(address(this)), "Not enough tokens available for sale");

        // Transfer ETH to the platform wallet
        platformWallet.transfer(msg.value);

        // Transfer tokens to the buyer
        token.transfer(msg.sender, tokenAmount);

        saleSupply += tokenAmount;

        emit TokensPurchased(msg.sender, tokenAmount, 0, msg.value);
    }
}