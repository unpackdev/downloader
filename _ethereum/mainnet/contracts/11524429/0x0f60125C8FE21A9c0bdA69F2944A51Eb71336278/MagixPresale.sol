// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "./ReentrancyGuard.sol";
import "./Context.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./SafeERC20.sol";

import "./Interfaces.sol";

interface IMagix is IERC20 {
    function uniswapV2Pair() external view returns (address);
}

contract MagixPresale is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IUniswapV2Router02 constant uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address constant burnAddr = 0x000000000000000000000000000000000000dEaD;

    IERC20 public _token;
    IERC20 public _pool;

    uint256 constant HARD_CAP = 333 ether;
    uint256 constant MIN_VALUE = 0.1 ether;
    uint256 constant MIN_PRIV_VALUE = 0.5 ether;
    uint256 constant MAX_ADDR_CAP = 3 ether;

    uint256 constant TOKENS_PER_ETH = 1200;
    uint256 constant LISTING_TOKENS_PER_ETH = 900;
    uint256 constant LIQUIDITY_LOCK = 80; // %

    uint256 public startTime = 0;
    uint256 public timeWhitelistSale = 15 minutes;

    bool public isStopped = false;
    bool public isRefundEnabled = false;
    bool public presaleStarted = false;
    bool public finalized = false;
    bool public liquidityAdded = false;

    uint256 public tokensSold;
    uint256 public totalContributed;
    // Tracking unique contributors is expensive, let's consider that each purchase comes from a unique user
    uint256 public purchasesCount;

    uint256 public refundTime;

    mapping(address => uint256) contributions;
    mapping(address => bool) public PRIVLIST;

    constructor(IMagix token) public {
        _token = token;
        _pool = IERC20(token.uniswapV2Pair());

        refundTime = block.timestamp.add(2 days);
        PRIVLIST[msg.sender] = true;
    }

    receive() external payable {
        buyTokens();
    }

    function enableRefunds() external onlyOwner nonReentrant {
        isRefundEnabled = true;
        isStopped = true;
    }

    function batchAddWhitelisted(address[] calldata addrs) public onlyOwner {
        for (uint i = 0; i < addrs.length; i++) {
            PRIVLIST[addrs[i]] = true;
        }
    }

    function isPrivsalePhase() public view returns (bool) {
        return block.timestamp < startTime.add(timeWhitelistSale);
    }

    function getRefund() external nonReentrant {
        require(msg.sender == tx.origin);
        require(!liquidityAdded);
        // Refund should be enabled by the owner OR 7 days passed
        require(isRefundEnabled || block.timestamp >= refundTime, "Cannot refund");
        address payable user = msg.sender;
        uint256 amount = contributions[user];
        contributions[user] = 0;
        user.transfer(amount);
    }

    function setPrivatesaleDuration(uint256 newDuration) public onlyOwner {
        timeWhitelistSale = newDuration;
    }

    function startDistribution() external onlyOwner {
        startTime = block.timestamp;
        presaleStarted = true;
    }

    function pauseDistribution() external onlyOwner {
        presaleStarted = false;
    }

    function buyTokens() public payable nonReentrant {
        require(msg.sender == tx.origin, "No contract allowed");
        require(presaleStarted == true, "Presale has not yet started");
        require(PRIVLIST[msg.sender] || !isPrivsalePhase(), "Currently allowed only for whitelisted accounts");
        require(!isStopped, "Presale is closed");

        require(msg.value >= MIN_VALUE, "Min contribution is 0.1 ETH");
        require(msg.value >= MIN_PRIV_VALUE || !isPrivsalePhase(), "Min contribution in whitelist sale is 0.5ETH");
        require(msg.value <= MAX_ADDR_CAP, "Max contribution is 3 ETH");
        require(totalContributed < HARD_CAP, "Hard cap reached");
        require(msg.value.add(totalContributed) <= HARD_CAP, "Hardcap will be reached");
        require(contributions[msg.sender].add(msg.value) <= MAX_ADDR_CAP, "Address cap is reached, you cannot buy more");

        uint256 tokens = msg.value.mul(TOKENS_PER_ETH).div(1e9);
        require(_token.balanceOf(address(this)) >= tokens, "Not enough tokens in the presale contract");

        contributions[msg.sender] = contributions[msg.sender].add(msg.value);
        tokensSold = tokensSold.add(tokens);
        totalContributed = totalContributed.add(msg.value);
        purchasesCount += 1;

        _token.transfer(msg.sender, tokens);
    }

    function userContribution(address account) external view returns (uint256) {
        return contributions[account];
    }

    function finalize() external onlyOwner {
        require(!finalized);

        uint256 collectedETH = address(this).balance;
        uint256 liquidityETH = collectedETH.mul(LIQUIDITY_LOCK).div(100);
        uint256 autoLockETH = liquidityETH.mul(40).div(100);
        uint256 remainingETH = collectedETH.sub(autoLockETH);

        addLiquidity(autoLockETH);
        payable(owner()).transfer(remainingETH);

        finalized = true;
        isStopped = true;
    }

    function addLiquidity(uint256 ethValue) internal {
        uint256 tokensForUniswap = ethValue.mul(LISTING_TOKENS_PER_ETH).div(1e9);
        uint256 tokensExcess = _token.balanceOf(address(this)).sub(tokensForUniswap);

        _token.approve(address(uniswapRouter), tokensForUniswap);

        uniswapRouter.addLiquidityETH{value : ethValue}(
            address(_token),
            tokensForUniswap,
            tokensForUniswap,
            ethValue,
            owner(),
            block.timestamp
        );

        // Send remaining to the owner so we can burn the specific amount
        if (tokensExcess > 0) {
            _token.transfer(owner(), tokensExcess);
        }

        liquidityAdded = true;
    }
}