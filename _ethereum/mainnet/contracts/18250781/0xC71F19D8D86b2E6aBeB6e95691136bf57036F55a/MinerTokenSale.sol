// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity 0.8.19;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity 0.8.19;

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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity 0.8.19;


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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.19;

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


pragma solidity 0.8.19;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

}

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

/**
 * @title MinerTokenSale
 * @dev A contract for conducting a token sale.
 */
contract MinerTokenSale is Ownable, ReentrancyGuard {
    address private MinerCoin;
    uint256 private tokenPrice;
    bytes32 private merkleRoot;
    uint256 private saleStartTime;
    uint256 private saleEndTime;
    uint256 private whitelistSaleStartTime;
    uint256 private whitelistSaleEndTime;
    uint256 private maxTokensToSell;
    uint256 private totalTokensSold;
    uint256 private maxWalletLimit;
    AggregatorV3Interface private eth_priceFeed;

    mapping(address => bool) private isTokenAllowed;
    mapping(address => uint256) private tokensPurchased;

    event TokenPurchased(address indexed buyer, uint256 amountPurchased, address token);

    constructor() {
        // ETH
        isTokenAllowed[address(0)] = true;

        // USDC
        isTokenAllowed[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = true;

        // USDT 
        isTokenAllowed[0xdAC17F958D2ee523a2206206994597C13D831ec7] = true;

        eth_priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

        maxWalletLimit = 3_000_000 ether;

        maxTokensToSell = 10_000_000 ether;

        tokenPrice = 9_000_000_000_000_000;

        MinerCoin = 0x712b4608a8b565BCA365D49A4c26d669Ce6CEE08;

        saleStartTime = 1696111200;
        saleEndTime = 1696197600;
    }

    modifier onlyDuringSale() {
        // Ensures that the token sale is active.
        require(
            block.timestamp >= saleStartTime && block.timestamp <= saleEndTime,
            "Miner: Token sale is not active"
        );
        _;
    }

    modifier onlyDuringWhitelistSale() {
        // Ensures that the whitelist sale is active.
        require(
            block.timestamp >= whitelistSaleStartTime && block.timestamp <= whitelistSaleEndTime,
            "Miner: Whitelist sale is not active"
        );
        _;
    }

    /**
     * @dev Sets the maximum number of tokens to sell.
     * @param amount The maximum number of tokens to sell.
     */
    function setMaxTokensToSell(uint256 amount) external onlyOwner {
        maxTokensToSell = amount;
    }

    /**
     * @dev Sets the maximum wallet limit.
     * @param amount The maximum wallet limit.
     */
    function setMaxWalletLimit(uint256 amount) external onlyOwner {
        maxWalletLimit = amount;
    }

    /**
     * @dev Sets the token price.
     * @param _newTokenPrice The new token price.
     */
    function setTokenPrice(uint256 _newTokenPrice) external onlyOwner {
        tokenPrice = _newTokenPrice;
    }

    /**
     * @dev Sets the Merkle root for verifying whitelist purchases.
     * @param _newMerkleRoot The new Merkle root.
     */
    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    /**
     * @dev Sets the start time of the token sale.
     * @param _newSaleStartTime The new start time of the token sale.
     */
    function setSaleStartTime(uint256 _newSaleStartTime) external onlyOwner {
        saleStartTime = _newSaleStartTime;
    }

    /**
     * @dev Sets whether a token is allowed for purchase.
     * @param token The address of the token.
     * @param status The status indicating whether the token is allowed.
     */
    function setTokenAllowed(address token, bool status) external onlyOwner {
        isTokenAllowed[token] = status;
    }

    /**
     * @dev Sets the end time of the token sale.
     * @param _newSaleEndTime The new end time of the token sale.
     */
    function setSaleEndTime(uint256 _newSaleEndTime) external onlyOwner {
        saleEndTime = _newSaleEndTime;
    }

    /**
     * @dev Sets the start time of the whitelist sale.
     * @param _newWhitelistSaleStartTime The new start time of the whitelist sale.
     */
    function setWhitelistSaleStartTime(uint256 _newWhitelistSaleStartTime) external onlyOwner {
        whitelistSaleStartTime = _newWhitelistSaleStartTime;
    }

    /**
     * @dev Sets the end time of the whitelist sale.
     * @param _newWhitelistSaleEndTime The new end time of the whitelist sale.
     */
    function setWhitelistSaleEndTime(uint256 _newWhitelistSaleEndTime) external onlyOwner {
        whitelistSaleEndTime = _newWhitelistSaleEndTime;
    }

    /**
     * @dev Sets the ETH Price Feed.
     * @param _newETHPriceFeed The new price feed.
     */
    function setETHPriceFeed(address _newETHPriceFeed) external onlyOwner {
        eth_priceFeed = AggregatorV3Interface(_newETHPriceFeed);
    }

    /**
     * @dev Gets the address of the ETH price feed aggregator.
     * @return The address of the ETH price feed aggregator.
     */
    function getETHPriceFees() external view returns (address) {
        return address(eth_priceFeed);
    }

    /**
     * @dev Gets the token purchase details for a specific wallet address.
     * @param wallet The wallet address.
     * @return The token purchase details.
     */
    function getPurchasedTokens(address wallet) external view returns (uint256) {
        return tokensPurchased[wallet];
    }

    /**
     * @dev Gets the token price.
     * @return The token price.
     */
    function getTokenPrice() external view returns (uint256) {
        return tokenPrice;
    }

    /**
     * @dev Gets the Merkle root.
     * @return The Merkle root.
     */
    function getMerkleRoot() external view returns (bytes32) {
        return merkleRoot;
    }

    /**
     * @dev Gets the start time of the token sale.
     * @return The start time of the token sale.
     */
    function getSaleStartTime() external view returns (uint256) {
        return saleStartTime;
    }

    /**
     * @dev Gets the end time of the token sale.
     * @return The end time of the token sale.
     */
    function getSaleEndTime() external view returns (uint256) {
        return saleEndTime;
    }

    /**
     * @dev Gets the start time of the whitelist sale.
     * @return The start time of the whitelist sale.
     */
    function getWhitelistSaleStartTime() external view returns (uint256) {
        return whitelistSaleStartTime;
    }

    /**
     * @dev Gets the end time of the whitelist sale.
     * @return The end time of the whitelist sale.
     */
    function getWhitelistSaleEndTime() external view returns (uint256) {
        return whitelistSaleEndTime;
    }

    /**
     * @dev Gets the maximum number of tokens to sell.
     * @return The maximum number of tokens to sell.
     */
    function getMaxTokensToSell() external view returns (uint256) {
        return maxTokensToSell;
    }

    /**
     * @dev Gets the total number of tokens sold.
     * @return The total number of tokens sold.
     */
    function getTotalTokensSold() external view returns (uint256) {
        return totalTokensSold;
    }

    /**
     * @dev Gets the maximum wallet limit.
     * @return The maximum wallet limit.
     */
    function getMaxWalletLimit() external view returns (uint256) {
        return maxWalletLimit;
    }

    /**
     * @dev Gets the Miner Coin Address.
     * @return Miner Coin Address.
     */
    function getMinerCoin() external view returns (address) {
        return MinerCoin;
    }
    
    /**
     * @dev Gets the ETH price from the price feed aggregator.
     * @return The ETH price in USD.
     */
    function getETHPrice() public view returns (uint) {
        (uint80 roundId, , , , ) = eth_priceFeed.latestRoundData();
        uint256 round_ = (roundId / 10) * 10; 
        (, int price, , , ) = eth_priceFeed.getRoundData(uint80(round_));
        require(price >= 0, "Miner: Invalid Price Feed Data");
        return uint256(price);
    }

    /**
     * @dev Gets the decimals of the ETH price feed.
     * @return The number of decimals of the ETH price feed.
     */
    function priceFeedDecimals() public view returns(uint){
        return eth_priceFeed.decimals();
    }

    /**
     * @dev Gets the equivalent amount of ETH for a given USD amount.
     * @param amountInUSD The USD amount.
     * @return The equivalent amount of ETH.
     */
    function getETHAmount(uint256 amountInUSD) public view returns(uint256){
        uint256 amount = (amountInUSD * (10**priceFeedDecimals())) / getETHPrice();
        return amount;
    }
    
    /**
     * @dev Performs a purchase during the public sale period.
     * @param amountInUSD The USD amount.
     * @param token The address of the token.
     */
    function publicPurchase(uint256 amountInUSD, address token) external payable onlyDuringSale nonReentrant {
        require(amountInUSD > 0, "Miner: Purchase should not be zero");
        require(isTokenAllowed[token] == true, "Miner: Token not allowed");
        if(token == address(0)) {
            uint256 ethValue = getETHAmount(amountInUSD);
            require(ethValue > 0, "Miner: ETH value should be greater than zero");
            require(msg.value == ethValue, "Miner: Please send proper ETH Amount");
            payable(owner()).transfer(msg.value);
        } else {
            TransferHelper.safeTransferFrom(token, _msgSender(), owner(), amountInUSD);
            amountInUSD = amountInUSD * 10**12; // Converting USDT/USDC amount to 18 decimals
        }

        uint256 tokenAmount = (amountInUSD * 10**18) / tokenPrice;

        totalTokensSold += tokenAmount;
        require(totalTokensSold <= maxTokensToSell, "Miner: Max Limit Reached");

        tokensPurchased[_msgSender()] += tokenAmount;
        require(tokensPurchased[_msgSender()] <= maxWalletLimit, "Miner: Max Wallet Limit Reached");
        TransferHelper.safeTransfer(MinerCoin, _msgSender(), tokenAmount);

        emit TokenPurchased(_msgSender(), tokenAmount, token);
    }

    /**
     * @dev Withdraws the unsold tokens to the owner.
     * @param token The address of the token.
     * @param amount The amount of unsold tokens to withdraw.
     */
    function withdrawTokens(address token, uint256 amount) external onlyOwner nonReentrant {
        require(token != address(0), "Miner: ETH cannot be withdrawn using this function");
        TransferHelper.safeTransfer(token, owner(), amount);
    }

    /**
     * @dev Withdraws the ETH balance to the owner.
     */
    function withdrawETHBalance(uint256 amount) external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance >= amount, "Miner: No ETH balance to withdraw");
        payable(owner()).transfer(amount);
    }

    /**
     * @dev Receives ETH payments sent to the contract.
     */
    receive() external payable {}
}