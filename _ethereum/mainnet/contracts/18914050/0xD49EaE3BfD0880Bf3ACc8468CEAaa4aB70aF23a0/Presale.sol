// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
}

contract Presale {
    address public owner;
    IERC20 public token; 
    uint256 public totalETHRaised;
    uint256 public presaleStartTime; 
    uint256 public presaleEndTime;
    uint256 public tokenPricePerETH; // Number of tokens per 1 ETH
    bool public presaleActive = false;

    mapping(address => uint256) public ETHContributions;
    mapping(address => uint256) public tokenBalances;
    bool public withdrawalAllowed = false;

    event PresaleStarted(uint256 startTime, uint256 endTime);
    event PresaleStopped();
    event PriceChanged(uint256 newPrice);
    event ETHContributed(address indexed contributor, uint256 amount);
    event TokensClaimed(address indexed claimer, uint256 amount);

    mapping(address => uint256) public lastClaimTime;
    mapping(address => uint256) public claimedAmount;
    uint256 public constant minDaysBetweenClaims = 7 days;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address tokenAddress, uint256 _tokenPricePerETH) {
        owner = msg.sender;
        token = IERC20(tokenAddress);
        tokenPricePerETH = _tokenPricePerETH;
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

    function setTokenPricePerETH(uint256 newPrice) public onlyOwner {
        require(presaleActive, "Presale is not active");
        require(block.timestamp < presaleEndTime, "Cannot change price after presale ended");
        tokenPricePerETH = newPrice;
        emit PriceChanged(newPrice);
    }

    function contribute() public payable {
        require(presaleActive, "Presale is not active");
        require(block.timestamp < presaleEndTime, "Presale ended");
        payable(owner).transfer(msg.value);
        
        totalETHRaised += msg.value;
        uint256 tokenAmount = msg.value * tokenPricePerETH;
        
       tokenBalances[msg.sender] += tokenAmount;

        ETHContributions[msg.sender] += msg.value;
        emit ETHContributed(msg.sender, msg.value);
    }

    function claimTokens() public {
        require(!presaleActive, "Presale is active");
        require(withdrawalAllowed, "Withdrawals not Enabled yet");
        require(block.timestamp > presaleEndTime, "Presale not ended");
        require(ETHContributions[msg.sender] > 0, "No contribution made");
        
        uint256 tokenAmount = tokenBalances[msg.sender];
        
        // Calculate the number of days since the last claim
        uint256 daysSinceLastClaim = block.timestamp - lastClaimTime[msg.sender];
        
        // Ensure the user has waited at least minDaysBetweenClaims
        require(daysSinceLastClaim >= minDaysBetweenClaims, "Minimum time between claims not met");
        
        // Calculate the amount to claim (25% of tokens)
        uint256 amountToClaim = (tokenAmount * 25) / 100;
        
        // Ensure the total claimed amount doesn't exceed 100%
        require(claimedAmount[msg.sender] + amountToClaim <= tokenAmount, "Total claimed exceeds 100%");
        
        // Update the last claim time and claimed amount
        lastClaimTime[msg.sender] = block.timestamp;
        claimedAmount[msg.sender] += amountToClaim;

         // Transfer tokens to the sender
        require(token.transfer(msg.sender, amountToClaim), "Token transfer failed");
        
        emit TokensClaimed(msg.sender, amountToClaim);
    }

    receive() external payable {
        contribute();
    }

    function AmountTobeClaimed(address _investor) public view returns(uint256){
        return tokenBalances[_investor];
    }

    function RemainingAmountTobeClaimed(address _investor) public view returns(uint256){
        return tokenBalances[_investor] - claimedAmount[_investor];
    }

    function saveRemainingTokens(address tokenAddress) external onlyOwner {
        IERC20 token1 = IERC20(tokenAddress);
        uint256 tokenBalance = token1.balanceOf(address(this));
        token1.transfer(owner, tokenBalance);
    }

    function toggleWithdrawals() public onlyOwner {
        withdrawalAllowed = !withdrawalAllowed;
    }

}