// SPDX-License-Identifier: MIT
//Developed by: NarcosLand

pragma solidity 0.8.19;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
}

contract Presale {
    address public owner;
    IERC20 public token; 
    uint256 public totalTokensForSale;
    uint256 public totalETHRaised;
    uint256 public presaleStartTime; 
    uint256 public presaleEndTime;
    uint256 public maxPerWallet;
    uint256 public tokenPricePerETH; // Number of tokens per 1 ETH
    bool public presaleActive = false;

    mapping(address => uint256) public ETHContributions;
    bool public withdrawalAllowed = true;

    event PresaleStarted(uint256 startTime, uint256 endTime);
    event PresaleStopped();
    event PriceChanged(uint256 newPrice);
    event ETHContributed(address indexed contributor, uint256 amount);
    event TokensClaimed(address indexed claimer, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address tokenAddress, uint256 _totalTokensForSale, uint256 _tokenPricePerETH) {
        owner = msg.sender;
        token = IERC20(tokenAddress);
        totalTokensForSale = _totalTokensForSale;
        tokenPricePerETH = _tokenPricePerETH;
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

    function setTokenPricePerETH(uint256 newPrice) public onlyOwner {
        require(presaleActive, "Presale is not active");
        require(block.timestamp < presaleEndTime, "Cannot change price after presale ended");
        tokenPricePerETH = newPrice;
        emit PriceChanged(newPrice);
    }

    function contribute() public payable {
        require(presaleActive, "Presale is not active");
        require(block.timestamp < presaleEndTime, "Presale ended");
        require(msg.value <= maxPerWallet, "Exceeds max per wallet");
        require(ETHContributions[msg.sender] + msg.value <= maxPerWallet, "Exceeds max contribution per wallet");
        
        totalETHRaised += msg.value;
        ETHContributions[msg.sender] += msg.value;
        payable(owner).transfer(msg.value);

        emit ETHContributed(msg.sender, msg.value);
    }

    function claimTokens() public {
        require(withdrawalAllowed, "Withdrawals not Enabled yet");
        require(block.timestamp > presaleEndTime, "Presale not ended");
        require(ETHContributions[msg.sender] > 0, "No contribution made");

        uint256 tokenAmount = ETHContributions[msg.sender] * tokenPricePerETH;
        ETHContributions[msg.sender] = 0;

        require(token.transfer(msg.sender, tokenAmount), "Token transfer failed");
        emit TokensClaimed(msg.sender, tokenAmount);
    }

    receive() external payable {
        contribute();
    }

    function AmountTobeClaimed(address _investor) public view returns(uint256){
        return ETHContributions[_investor] * tokenPricePerETH;
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