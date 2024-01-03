// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);
}

contract PresaleUSDT {
    address public owner;
    IERC20 public token; 
    IERC20 public usdt;
    uint256 public totalUSDTRaised;
    uint256 public presaleStartTime; 
    uint256 public presaleEndTime;
    uint256 public tokenPrice; // Price of 1 token in USDT
    bool public presaleActive = false;

    mapping(address => uint256) public usdtContributions;
    mapping(address => uint256) public tokenBalances;
    bool public withdrawalAllowed = false;

    event PresaleStarted(uint256 startTime, uint256 endTime);
    event PresaleStopped();
    event PriceChanged(uint256 newPrice);
    event UsdtContributed(address indexed contributor, uint256 amount);
    event TokensClaimed(address indexed claimer, uint256 amount);

    mapping(address => uint256) public lastClaimTime;
    mapping(address => uint256) public claimedAmount;

    uint256 public constant minDaysBetweenClaims = 7 days;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address tokenAddress, address usdtAddress, uint256 _tokenPrice) {
        owner = msg.sender;
        token = IERC20(tokenAddress);
        usdt = IERC20(usdtAddress);
        tokenPrice = _tokenPrice;
    }

    function startPresale(uint256 duration) public onlyOwner {
        presaleStartTime = block.timestamp;
        presaleEndTime = presaleStartTime + duration;
        presaleActive = true;
        emit PresaleStarted(presaleStartTime, presaleEndTime);
    }

    function stopPresale() public onlyOwner {
        presaleActive = false;
        presaleEndTime = block.timestamp;
        emit PresaleStopped();
    }

    function setTokenPrice(uint256 newPrice) public onlyOwner {
        require(presaleActive, "Presale is not active");
        require(block.timestamp < presaleEndTime, "Cannot change price after presale ended");
        tokenPrice = newPrice;
        emit PriceChanged(newPrice);
    }

    function contributeWithUSDT(uint256 usdtAmount) public {
        require(presaleActive, "Presale is not active");
        require(block.timestamp < presaleEndTime, "Presale ended");
        
        require(usdt.transferFrom(msg.sender, address(owner), usdtAmount), "USDT transfer failed");
        uint256 tokenAmount = usdtAmount / tokenPrice;
        
        usdtContributions[msg.sender] += usdtAmount;
        tokenBalances[msg.sender] += tokenAmount;
        totalUSDTRaised += usdtAmount;
 
        emit UsdtContributed(msg.sender, usdtAmount);
    }

    function claimTokens() public {
        require(!presaleActive, "Presale is active");
        require(withdrawalAllowed, "Withdrawals not Enabled yet");
        require(block.timestamp > presaleEndTime, "Presale not ended");
        require(tokenBalances[msg.sender] > 0, "No tokens to claim");
        
        // Calculate the number of days since the last claim
        uint256 daysSinceLastClaim = block.timestamp - lastClaimTime[msg.sender];
        
        // Ensure the user has waited at least 7 days since the last claim
        require(daysSinceLastClaim >= minDaysBetweenClaims, "Minimum time between claims not met");
        
        // Calculate the amount to claim (25% of tokens)
        uint256 tokenAmountToClaim = (tokenBalances[msg.sender] * 25) / 100;
        
        // Ensure the total claimed amount plus the current claim amount doesn't exceed 100%
        require(claimedAmount[msg.sender] + tokenAmountToClaim <= tokenBalances[msg.sender], "Total claimed exceeds 100%");
        
        // Transfer tokens to the sender
        require(token.transfer(msg.sender, tokenAmountToClaim * 1e18), "Token transfer failed");
        
        // Update the last claim time and claimed amount
        lastClaimTime[msg.sender] = block.timestamp;
        claimedAmount[msg.sender] += tokenAmountToClaim;
        
        emit TokensClaimed(msg.sender, tokenAmountToClaim);
    }


    function saveRemainingTokens(address tokenAddress) external onlyOwner {
        IERC20 token1 = IERC20(tokenAddress);
        uint256 tokenBalance = token1.balanceOf(address(this));
        token1.transfer(owner, tokenBalance);
    }

    function AmountTobeClaimed(address _investor) public view returns(uint256){
        return tokenBalances[_investor] * 1e18;
    }

    function RemainingAmountTobeClaimed(address _investor) public view returns(uint256){
        return (tokenBalances[_investor] - claimedAmount[_investor]) * 1e18;
    }

    function saveRemainingUSDT() external onlyOwner {
        uint256 usdtBalance = usdt.balanceOf(address(this));
        require(usdt.transfer(owner, usdtBalance), "USDT transfer failed");
    }

    function saveETH() public onlyOwner{
        payable(owner).transfer(address(this).balance);
    }

    function toggleWithdrawals() public onlyOwner {
        withdrawalAllowed = !withdrawalAllowed;
    }

    receive() external payable {
        revert();
    }
}