// SPDX-License-Identifier: MIT
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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: contracts/tokensale.sol



pragma solidity ^0.8.17;



contract TokenSale is Ownable {
    IERC20 public token = IERC20(0x33D845D6E70ed8F6334C273358d1c5a320449C6F);
    uint8 public tokenDecimals = 3;
    IERC20 public USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    uint8 public USDTDecimals = 6;
    uint256 public conversionRate = 100; //in bips

    event LiquidityAdded(uint256 tokenAmount);
    event LiquidityRemoved(uint256 tokenAmount);
    event conversionRateUpdated(uint256 conversionRate);
    event tokenSold(address to, uint256 tokenAmount);
    event USDTWithdrawn(address to, uint256 USDTAmount);

    function fundContract(uint256 _tokenAmount) external onlyOwner {
        require(token.allowance(msg.sender, address(this)) >= _tokenAmount, "Insufficient token allowance");
        token.transferFrom(msg.sender, address(this), _tokenAmount);
        emit LiquidityAdded(_tokenAmount);
    }

    function buy(uint256 _USDTAmount) external {
        require(USDT.allowance(msg.sender, address(this)) >= _USDTAmount, "Insufficient USDT allowance");
        require(USDT.balanceOf(msg.sender) >= _USDTAmount, "Insuffient USDT balance in user address");
        uint256 _tokenAmount = (_USDTAmount * conversionRate/100)/1000 ;
        require(token.balanceOf(address(this)) >= _tokenAmount, "Insuffient liquidity for this trade");
        USDT.transferFrom(msg.sender, address(this), _USDTAmount);
        token.transfer(msg.sender, _tokenAmount);

        emit tokenSold(msg.sender, _tokenAmount);
    }

    function updateConversionRate(uint256 _conversionRate) external onlyOwner {
        conversionRate = _conversionRate;
        emit conversionRateUpdated(_conversionRate);
    }

    function withdrawUSDT(uint256 _amount, address _withdrawalAddress) external onlyOwner {
        require(USDT.balanceOf(address(this)) >= _amount, "Insufficient USDT balance in contract");
        USDT.transfer(_withdrawalAddress, _amount);

        emit USDTWithdrawn(_withdrawalAddress, _amount);

    }

    function withdrawToken(uint256 _amount, address _withdrawalAddress) external onlyOwner {
        require(token.balanceOf(address(this)) >= _amount, "Insufficient token balance in contract");
        token.transfer(_withdrawalAddress, _amount);

        emit LiquidityRemoved(_amount);
    }

    function getTokenLiquidity() view public returns(uint256) {
        return token.balanceOf(address(this));
    }

    ///// Admin Methods /////////////////

    function updateTokenDetails(address _tokenAddress, uint8 _tokenDecimals) external onlyOwner {
        token = IERC20(_tokenAddress);
        tokenDecimals = _tokenDecimals;
    }

    function updateUSDTDetails(address _USDTAddress, uint8 _USDTDecimals) external onlyOwner {
        USDT = IERC20(_USDTAddress);
        USDTDecimals = _USDTDecimals;
    }

}