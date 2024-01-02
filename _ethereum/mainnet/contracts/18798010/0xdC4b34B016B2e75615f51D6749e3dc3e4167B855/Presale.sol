// SPDX-License-Identifier: MIT
//Developed by: NarcosLand
pragma solidity 0.8.19;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);
}

contract Presale {
    address public owner;
    IERC20 public token; 
    IERC20 public usdt;
    uint256 public totalTokensForSale;
    uint256 public totalUSDTRaised;
    uint256 public presaleStartTime; 
    uint256 public presaleEndTime;
    uint256 public maxPerWallet;
    uint256 public tokenPrice; // Price of 1 token in USDT
    bool public presaleActive = false;

    mapping(address => uint256) public usdtContributions;
    mapping(address => uint256) public tokenBalances;
    bool public withdrawalAllowed = true;

    event PresaleStarted(uint256 startTime, uint256 endTime);
    event PresaleStopped();
    event PriceChanged(uint256 newPrice);
    event UsdtContributed(address indexed contributor, uint256 amount);
    event TokensClaimed(address indexed claimer, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address tokenAddress, address usdtAddress, uint256 _totalTokensForSale, uint256 _tokenPrice) {
        owner = msg.sender;
        token = IERC20(tokenAddress);
        usdt = IERC20(usdtAddress);
        totalTokensForSale = _totalTokensForSale;
        tokenPrice = _tokenPrice;
    }

    function startPresale(uint256 duration, uint256 _maxPerWallet) public onlyOwner {
        presaleStartTime = block.timestamp;
        presaleEndTime = presaleStartTime + duration;
        maxPerWallet = _maxPerWallet;
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
        require(usdtAmount <= maxPerWallet, "Exceeds max per wallet");
        require(usdtContributions[msg.sender] + usdtAmount <= maxPerWallet, "Exceeds max contribution per wallet");

        require(usdt.transferFrom(msg.sender, address(owner), usdtAmount), "USDT transfer failed");
        uint256 tokenAmount = usdtAmount / tokenPrice;
        
        usdtContributions[msg.sender] += usdtAmount;
        tokenBalances[msg.sender] += tokenAmount;
        totalUSDTRaised += usdtAmount;
 
        emit UsdtContributed(msg.sender, usdtAmount);
    }

    function claimTokens() public {
        require(withdrawalAllowed, "Withdrawals not Enabled yet");
        require(block.timestamp > presaleEndTime, "Presale not ended");
        require(tokenBalances[msg.sender] > 0, "No tokens to claim");

        uint256 tokenAmount = tokenBalances[msg.sender];
        tokenBalances[msg.sender] = 0;

        require(token.transfer(msg.sender, tokenAmount * 1e18), "Token transfer failed");
        emit TokensClaimed(msg.sender, tokenAmount);
    }

    function saveRemainingTokens(address tokenAddress) external onlyOwner {
        IERC20 token1 = IERC20(tokenAddress);
        uint256 tokenBalance = token1.balanceOf(address(this));
        token1.transfer(owner, tokenBalance);
    }

    function AmountTobeClaimed(address _investor) public view returns(uint256){
        return tokenBalances[_investor] * 1e18;
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

    receive() external payable {}
}