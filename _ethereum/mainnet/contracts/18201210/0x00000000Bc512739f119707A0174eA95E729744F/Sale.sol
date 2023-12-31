// SPDX-License-Identifier: UNLICENSED
// UPGRD is a community driven platform where users can build, collaborate, invest in projects and earn together.
// This contract is used to manage token sale.
// Author: UPGRD Labs
// Year: 2023
// Website: https://upgrd.dev
// Telegram: https://t.me/UPGRD_PORTAL
// Twitter: https://x.com/upgrd_dev

pragma solidity ^0.8.19;

import "./SafeTransferLib.sol";


import "./Managed.sol";


struct SaleMeta {
    bool    isStarted;
    bool    isCompleted;
    bool    isAllowed;
    address token;
    uint256 price;
    uint256 supply;
    uint256 sold;
    uint256 contributorsCount;
}

contract Sale is Managed {
    SaleMeta                    public  meta;
    mapping(address => uint256) public contributions;
    mapping(uint256 => address) public contributors;

    event Buy(address indexed to, uint256 amount, uint256 value);
    event Sell(address indexed to, uint256 amount, uint256 value);
    event FirstSale(address to);
    event LastSale(address to);

    error InsufficientAmount(uint256 amount);
    error SaleNotStarted();
    error SaleCompleted();
    error SaleNotAllowed();

    constructor(
        address owner_,
        address token,
        uint256 price
    ) {
        _initializeOwner(msg.sender);
        setTokenAndPrice(token, price);
        _initializeOwner(owner_);
    }

    // @dev Check if token sale is started and not completed
    modifier saleAllowed() {
        if (!meta.isStarted) revert SaleNotStarted();
        if (meta.isCompleted) revert SaleCompleted();
        _;
    }

    // @dev Check if token sale is allowed
    modifier isAllowed() {
        if (!meta.isAllowed) revert SaleNotAllowed();
        _;
    }

    // @dev Compute token amount for given wei amount
    // @dev Transfer tokens to sender and left over wei amount back to sender if any
    // @dev Emit Buy event
    function compute(uint256 amount) internal saleAllowed
    {
        (uint256 tokens, uint256 overflow) = getTokensForEthAmount(amount);

        meta.sold += tokens;
        // If all tokens are sold, mark sale as completed
        if(meta.supply == meta.sold) {
            meta.isCompleted = true;

            // Used to check if this is the last sale (for airdrop)
            emit LastSale(msg.sender);
        }
        
        // If this is the first sale, emit first sale event (for airdrop)
        if(meta.contributorsCount == 0) emit FirstSale(msg.sender);
        // If this is the first contribution of sender, add sender to contributors list
        if (contributions[msg.sender] == 0) contributors[meta.contributorsCount++] = msg.sender;
        // Update sender contribution
        contributions[msg.sender] += tokens;

        // Transfer tokens to sender
        if (tokens > 0) SafeTransferLib.safeTransfer(meta.token, msg.sender, tokens);
        // There should be no overflow, but just in case (at the end of sale, maybe somebody will send too much eth for remaining supply, so we will return it back to sender)
        if (overflow > 0) SafeTransferLib.forceSafeTransferETH(msg.sender, overflow);

        // Emit buy event
        emit Buy(msg.sender, tokens, amount - overflow);
    }

    // @dev Returns token amount and left over wei amount for given wei amount
    function getTokensForEthAmount(uint256 weiAmount) public view returns (uint256, uint256)
    {
        if (weiAmount == 0) return (0, 0);
        uint256 tokens = weiAmount * 10 ** 18 / meta.price;
        uint256 left = meta.supply - meta.sold;
        // If there is not enough tokens left, return all tokens left
        if(tokens > left) tokens = left;
        uint256 cost = (tokens * meta.price) / 10 ** 18;
        weiAmount -= cost;
        return (tokens, weiAmount);
    }

    // @dev Returns wei amount for given token amount
    function getEthForTokenAmount(uint256 tokenAmount) public view returns (uint256)
    {
        if (tokenAmount == 0) revert InsufficientAmount(tokenAmount);
        return (tokenAmount * meta.price) / 10 ** 18;
    }

    // @dev Allow to buy tokens back for eth (if needed)
    function refund(uint256 tokenAmount) public isAllowed
    {
        uint256 weiAmount = getEthForTokenAmount(tokenAmount);
        if (weiAmount == 0) revert InsufficientAmount(weiAmount);

        // Only allow to sell tokens that were bought by sender (protect against referral abuse)
        if (contributions[msg.sender] < tokenAmount) revert InsufficientAmount(tokenAmount);

        // Update sender contribution
        contributions[msg.sender] -= tokenAmount;
        // Update sold amount
        meta.sold -= tokenAmount;
        // Transfer token back to sale contract
        SafeTransferLib.safeTransferFrom(meta.token, msg.sender, address(this), tokenAmount);
        // Transfer eth back to sender
        SafeTransferLib.forceSafeTransferETH(msg.sender, weiAmount);
        // Emit sell event 
        emit Sell(msg.sender, tokenAmount, weiAmount);
    }

    // @dev Receive eth
    receive() external payable {
        compute(msg.value);
    }

    // @dev Fallback function to receive eth
    fallback() external payable {
        compute(msg.value);
    }

    // @dev Returns contributors addresses
    function getContributors(uint256 from, uint256 to) public view returns (address[] memory) {
        address[] memory result = new address[](to - from);
        for (uint256 i = from; i < to; i++) {
            result[i - from] = contributors[i];
        }
        return result;
    }

    // @dev Returns contributions of given addresses
    function getContributions(address[] memory addresses) public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            result[i] = contributions[addresses[i]];
        }
        return result;
    }

    // @dev Set token address and sell price
    function setTokenAndPrice(address token, uint256 price) public onlyOwner {
        meta.token = token;
        meta.price = price;
    }

    // @dev Set sale status
    function setSaleStatus(bool started, bool completed, bool allowed) public onlyOwner {
        meta.isStarted = started;
        meta.isCompleted = completed;
        meta.isAllowed = allowed;
    }

    // @dev Used to deposit tokens to sale contract and increase supply available for sale
    function deposit(uint256 amount) public onlyOwner {
        SafeTransferLib.safeTransferFrom(meta.token, msg.sender, address(this), amount);
        meta.supply += amount;
    }

    // @dev Used to withdraw tokens from sale contract and decrease supply available for sale (if needed)
    function release(uint256 amount) public onlyOwner {
        SafeTransferLib.safeTransfer(meta.token, msg.sender, amount);
        meta.supply -= amount;
    }

    // @dev Will end sale and withdraw all remaining tokens and eth from sale contract
    function finalize() public onlyOwner
    {
        meta.isCompleted = true;
        withdrawETH(0);
        withdrawToken(meta.token, 0);
    }

}


