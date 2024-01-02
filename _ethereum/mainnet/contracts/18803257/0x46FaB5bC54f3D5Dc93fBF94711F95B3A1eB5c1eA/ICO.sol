// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

// Interface for ERC20 tokens
interface IERC20 {
    // Returns the total token supply
    function totalSupply() external view returns (uint256);

    // Returns the token balance of an account
    function balanceOf(address account) external view returns (uint256);

    // Transfers tokens to a specified address
    function transfer(address recipient, uint256 amount) external returns (bool);

    // Returns the remaining number of tokens that the spender is allowed to spend
    function allowance(address owner, address spender) external view returns (uint256);

    // Sets the amount of tokens that an address is allowed to spend on behalf of another address
    function approve(address spender, uint256 amount) external returns (bool);

    // Transfers tokens from one address to another
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // Emitted when tokens are transferred, including zero value transfers
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Emitted when the allowance of a spender for an owner is set
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Interface for Uniswap V2 Router
interface IUniswapV2Router02 {
    // Returns the factory address
    function factory() external pure returns (address);

    // Returns the amount of tokens received for a given amount of input token
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    // Returns the WETH address
    function WETH() external pure returns (address);

    // Adds liquidity to the Uniswap pool
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);    
}

// Interface for Uniswap V2 Factory
interface IUniswapV2Factory {
    // Returns the pair address for two tokens
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    // Creates a pair for two tokens
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// Interface for AggregatorV3 (Chainlink Price Feeds)
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);
    function getRoundData(uint80 _roundId) external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}


contract ICO {
    IERC20 public token;
    AggregatorV3Interface internal priceFeed;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public admin;

    uint256 public hardCap;
    uint256 public softCap;
    uint256 public startTimestamp;
    uint256 public endTimestamp;

    uint256 public raisedAmount;
    bool public isICOActive;
    bool public softCapReached;
    bool public ICOCompleted;

    uint256 public timeUnit;
    address[] public contributors;
    mapping(address => uint256) public contributions;
    mapping(address => uint256) public brlsBought;

    event ContributionReceived(address indexed contributor, uint256 amount);
    event ContributionRefunded(address indexed contributor, uint256 amount);
    event TokensDistributed(address indexed recipient, uint256 amount);
    event ICOStarted(uint256 timestamp);
    event ICOEnded(uint256 timestamp);
    event AdminUpdated(address newAdmin);
    event ICOPaused();
    event ICOResumed();

    constructor() {
        token = IERC20(0x6DEE1574DBae7f0d49153F8Cd5ef6d714399c86B); 
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); // Chainlink price feed address

        admin = msg.sender; 
        softCap = 2500 ether; // adjust as needed
        hardCap = 25000 ether; // adjust as needed
        timeUnit = 1 days; // Adjust as per requirement

        // Initialize the Uniswap pair
        address _pair = IUniswapV2Factory(uniswapV2Router.factory())
            .getPair(address(token), uniswapV2Router.WETH());
        if(_pair == address(0)) {
            _pair = IUniswapV2Factory(uniswapV2Router.factory())
                .createPair(address(token), uniswapV2Router.WETH());
        }
        uniswapV2Pair = _pair;
    }

    modifier onlyWhileICOActive() {
        require(isICOActive, "ICO is not active");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    function contribute() external payable onlyWhileICOActive {
        require(msg.value > 0, "Contribution must be positive");
        require(block.timestamp < endTimestamp, "ICO Time is over");
        if(contributions[msg.sender] == 0) {
            contributors.push(msg.sender);
        }
        contributions[msg.sender] += msg.value;
        raisedAmount += msg.value;

        uint256 tokens = calculateTokens(msg.value);
        brlsBought[msg.sender] += tokens;

        require(raisedAmount <= hardCap, "Hard cap reached");
        if (raisedAmount >= softCap) {
            softCapReached = true;
        }

        emit ContributionReceived(msg.sender, msg.value);
    }

    function calculateTokens(uint256 ethAmountInWei) internal view returns (uint256) {
        uint256 currentPhase = getStage();
        int ethPrice = getLatestETHPrice(); 

        uint256 usdAmount = (uint256(ethPrice) * ethAmountInWei) / 1e26; 
        uint256 tokensPerUSDT = currentPhase == 0 ? 100 : (currentPhase == 1 ? 33 : 20);

        return usdAmount * tokensPerUSDT;
    }

    function getLatestETHPrice() public view returns (int) {
        (,int price,,,) = priceFeed.latestRoundData();
        return price;
    }

    function getStage() public view returns (uint256) {
        uint256 elapsed = block.timestamp - startTimestamp;
        if (elapsed < 15 * timeUnit) {
            return 0; // Phase 1
        } else if (elapsed < 30 * timeUnit) {
            return 1; // Phase 2
        } else {
            return 2; // Phase 3
        }
    }

    function startICO() public onlyAdmin {
        require(!isICOActive, "ICO already active");
        startTimestamp = block.timestamp;
        endTimestamp = block.timestamp + 45 days; 
        isICOActive = true;
        emit ICOStarted(block.timestamp);
    }

    function endICO() public onlyAdmin {
        require(isICOActive, "ICO not active");
        require(block.timestamp >= endTimestamp || raisedAmount >= hardCap, "ICO cannot be ended yet");
        isICOActive = false;
        ICOCompleted = true;
        emit ICOEnded(block.timestamp);
    }

    function distributeTokens() public onlyAdmin {
        require(ICOCompleted, "ICO not completed");
        require(softCapReached, "Soft cap not reached");
    
        uint8 tokenDecimals = 18; 

        for (uint256 i = 0; i < contributors.length; i++) {
            address contributor = contributors[i];
            uint256 tokens = brlsBought[contributor];

            if (tokens > 0) {
                uint256 tokensToSend = tokens * (10 ** tokenDecimals);
                require(token.balanceOf(address(this)) >= tokensToSend, "Insufficient tokens in contract");
            
                token.transfer(contributor, tokensToSend);
                brlsBought[contributor] = 0;
                emit TokensDistributed(contributor, tokensToSend);
            }
        }
    }

    // Function to refund contributors if soft cap is not reached
    function refundContributors() internal {
        require(!softCapReached, "Soft cap reached, refund not possible");
        for (uint256 i = 0; i < contributors.length; i++) {
            address contributor = contributors[i];
            uint256 contribution = contributions[contributor];
            if (contribution > 0) {
                payable(contributor).transfer(contribution);
                contributions[contributor] = 0;
                emit ContributionRefunded(contributor, contribution);
            }
        }
    }

    function pauseICO() public onlyAdmin {
        require(isICOActive, "ICO not active");
        isICOActive = false;
        emit ICOPaused();
    }

    function resumeICO() public onlyAdmin {
        require(!isICOActive, "ICO already active");
        isICOActive = true;
        emit ICOResumed();
    }

    function updateAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "Invalid address");
        admin = newAdmin;
        emit AdminUpdated(newAdmin);
    }

    /*
        Function to add liquidity to a decentralized exchange (e.g., Uniswap)
    */

    function addLiquidity(uint256 ethAmount, uint256 tokenAmount) external onlyAdmin {
        uniswapV2Router.addLiquidityETH{value: ethAmount} (
            address(token), 
            tokenAmount,
            0, 
            0, 
            admin,
            block.timestamp + 30
        );
    }

    // Function to withdraw funds by admin if soft cap is reached
    function withdrawFunds() public onlyAdmin {
        require(softCapReached, "Soft cap not reached");
        payable(admin).transfer(address(this).balance);
    }

    // Emergency token recovery function
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyAdmin {
        IERC20(tokenAddress).transfer(admin, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    // Event to log the recovery action
    event Recovered(address token, uint256 amount);

   // Allow the contract to receive Ether
    receive() external payable {}

    // Fallback function in case Ether is sent to the contract by mistake
    fallback() external payable {}
}