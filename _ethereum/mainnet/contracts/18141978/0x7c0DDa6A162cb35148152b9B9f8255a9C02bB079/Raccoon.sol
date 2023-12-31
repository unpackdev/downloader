//  .S_sSSs     .S_SSSs      sSSs    sSSs    sSSs_sSSs      sSSs_sSSs     .S_RACs    
// .SS~YS%%b   .SS~SSSSS    d%%SP   d%%SP   d%%SP~YS%%b    d%%SP~YS%%b   .SS~YS%%b   
// S%S   `S%b  S%S   SSSS  d%S'    d%S'    d%S'     `S%b  d%S'     `S%b  S%S   `S%b  
// S%S    S%S  S%S    S%S  S%S     S%S     S%S       S%S  S%S       S%S  S%S    S%S  
// S%S    d*S  S%S SSSS%S  S&S     S&S     S&S       S&S  S&S       S&S  S%S    S&S  
// S&S   .S*S  S&S  SSS%S  S&S     S&S     S&S       S&S  S&S       S&S  S&S    S&S  
// S&S_sdSSS   S&S    S&S  S&S     S&S     S&S       S&S  S&S       S&S  S&S    S&S  
// S&S~YSY%b   S&S    S&S  S&S     S&S     S&S       S&S  S&S       S&S  S&S    S&S  
// S*S   `S%b  S*S    S&S  S*b     S*b     S*b       d*S  S*b       d*S  S*S    S*S  
// S*S    S%S  S*S    S*S  S*S.    S*S.    S*S.     .S*S  S*S.     .S*S  S*S    S*S  
// S*S    S&S  S*S    S*S   SSSbs   SSSbs   SSSbs_sdSSS    SSSbs_sdSSS   S*S    S*S  
// S*S    SSS  SSS    S*S    YSSP    YSSP    YSSP~YSSY      YSSP~YSSY    S*S    SSS  
// SP                 SP          Do You Raccoon?                                SP          
//                                                                                
//                                                                                  
/**
 * @title RaccoonCoin (RAC): An Innovative Limited Supply Token
 * @dev Welcome to RaccoonCoin, where innovation meets finance. Join the raccoon party!
 * Learn how to use RAC tokens effectively, explore our tokenomics, and become part of our growing community.
 *
 * How to Use:
 * - Secure your RAC tokens during the initial 7-day launch phase.
 * - To buy RAC:
 *   - Ensure the launch period is active.
 *   - Send a minimum of 0.1 ETH to the contract address using the Buy function.
 *   - Receive RAC tokens at the current rate.
 * - Utilize the power of Uniswap V3 for seamless trading.
 * - Stake your RAC tokens to earn rewards within our ecosystem.
 * - Claim staking rewards while holding and participating.
 *
 * Tokenomics:
 * - Total Supply: 1 Billion and One (1,000,000,001 RAC).
 * - 5% allocated to RaccoonTeam for project support.
 * - A significant 22% reserved for our staking pool, ensuring long-term sustainability and community benefits.
 *
 * Join us in the exciting world of RaccoonCoin and become part of our growing community!
 * SPDX-License-Identifier: Copyright Raccoon 2023
 */
pragma solidity ^0.8.18;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ISwapRouter.sol";

contract RaccoonCoin is ERC20, Ownable {
    using SafeMath for uint256;

    ISwapRouter public uniswapV3Router;
    uint256 public launchTime;

    uint256 public constant INCREASE_PERIOD = 7 days;
    uint256 public constant INITIAL_PRICE = 0.000000001287628738 ether;
    uint256 public constant MIN_PURCHASE_ETH = 0.1 ether;

    address public raccoonTeamAddress = 0x4E96980FD103afacdc23e366D0a670dB37787e7C;

    // Staking variables
    uint256 public stakingPool;
    mapping(address => uint256) public stakingBalance;
    mapping(address => uint256) public lastStakedTime;
    uint256 public stakingReleasePeriod = 365 days;

    constructor(address _uniswapV3Router) ERC20("RaccoonCoin", "RAC") {
        uint256 totalSupply = 1000000001 * 10 ** decimals();  // 1 Billion and One
        _mint(msg.sender, totalSupply);

        // Mint 5% of the total supply to RaccoonTeam
        uint256 raccoonTeamTokens = totalSupply.mul(5).div(100);
        _mint(raccoonTeamAddress, raccoonTeamTokens);

        // Reserve 22% for staking pool
        stakingPool = totalSupply.mul(22).div(100);

        // Initialize Uniswap V3 router
        ISwapRouter _uniswapV3Router = ISwapRouter(_uniswapV3Router);
        uniswapV3Router = _uniswapV3Router;
    }

    function setLaunchTime() external onlyOwner {
        launchTime = block.timestamp;
    }

    function getCurrentPrice() public view returns (uint256) {
        if (block.timestamp >= launchTime + INCREASE_PERIOD) {
            return INITIAL_PRICE;
        } else {
            uint256 elapsedTime = block.timestamp - launchTime;
            uint256 priceIncrease = (INITIAL_PRICE / INCREASE_PERIOD) * elapsedTime;
            return INITIAL_PRICE + priceIncrease;
        }
    }

    function buyTokens() external payable {
        require(block.timestamp < launchTime + INCREASE_PERIOD, "Direct buying period is over");
        require(msg.value >= MIN_PURCHASE_ETH, "Minimum purchase of 0.1 ETH required");

        uint256 currentPrice = getCurrentPrice();
        uint256 tokenAmount = msg.value.div(currentPrice);

        _transfer(address(this), msg.sender, tokenAmount);
    }

    // Staking functionalities

    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        stakingBalance[msg.sender] = stakingBalance[msg.sender].add(amount);
        lastStakedTime[msg.sender] = block.timestamp;

        _transfer(msg.sender, address(this), amount);
    }

    function unstake() external {
        uint256 stakerBalance = stakingBalance[msg.sender];
        require(stakerBalance > 0, "No staked tokens to unstake");

        uint256 timeStaked = block.timestamp.sub(lastStakedTime[msg.sender]);
        require(timeStaked >= stakingReleasePeriod, "Tokens are still staked");

        _transfer(address(this), msg.sender, stakerBalance);
        stakingBalance[msg.sender] = 0;
        lastStakedTime[msg.sender] = 0;
    }

    function claimStakingReward() external {
        uint256 stakerBalance = stakingBalance[msg.sender];
        require(stakerBalance > 0, "No staked tokens");

        uint256 timeStaked = block.timestamp.sub(lastStakedTime[msg.sender]);
        uint256 rewardAmount = stakerBalance.mul(timeStaked).div(stakingReleasePeriod);

        require(rewardAmount <= stakingPool, "Not enough tokens in the staking pool");

        _mint(msg.sender, rewardAmount);
        stakingPool = stakingPool.sub(rewardAmount);
    }
}