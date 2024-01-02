// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function swapTokensForTokens(uint256 amount, address recipient) external;
}

contract LiquiLendHub {
    struct TokenInfo {
        IERC20 token;
        uint256 depositAPY;
        uint256 borrowAPY;
        uint256 maxLTV;
        uint256 liquidationThreshold;
        uint256 liquidationPenalty;
        mapping(address => uint256) depositBalances;
        mapping(address => uint256) borrowBalances;
        mapping(address => uint256) depositTimestamps;
        mapping(address => uint256) borrowTimestamps;
        mapping(address => uint256) rewardBalances;
    }

    mapping(address => TokenInfo) public tokens;
    address public owner;
    bool public isDepositWithdrawActive;
    bool public isBorrowActive;
    IERC20 public GruxFi;
    IERC20 public GruxFiReward;

    constructor() {
        owner = msg.sender;
        isDepositWithdrawActive = false;
        isBorrowActive = false; 
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function updateTokenParameters(address _tokenAddress, uint256 _depositAPY, uint256 _borrowAPY, uint256 _maxLTV, uint256 _liquidationThreshold, uint256 _liquidationPenalty) external onlyOwner {
        TokenInfo storage token = tokens[_tokenAddress];
        require(address(token.token) != address(0), "Token not supported");
        token.depositAPY = _depositAPY;
        token.borrowAPY = _borrowAPY;
        token.maxLTV = _maxLTV;
        token.liquidationThreshold = _liquidationThreshold;
        token.liquidationPenalty = _liquidationPenalty;
    }

    // Function to add new token to the pool
    function addToken(address _tokenAddress, uint256 _depositAPY, uint256 _borrowAPY, uint256 _maxLTV, uint256 _liquidationThreshold, uint256 _liquidationPenalty) external onlyOwner {
        TokenInfo storage token = tokens[_tokenAddress];
        token.token = IERC20(_tokenAddress);
        token.depositAPY = _depositAPY;
        token.borrowAPY = _borrowAPY;
        token.maxLTV = _maxLTV;
        token.liquidationThreshold = _liquidationThreshold;
        token.liquidationPenalty = _liquidationPenalty;
    }

    // Deposit function
    function deposit(address _tokenAddress, uint256 _amount) external {
        require(isDepositWithdrawActive, "Pool is not active");
        TokenInfo storage token = tokens[_tokenAddress];
        require(address(token.token) != address(0), "Token not supported");

        token.token.transferFrom(msg.sender, address(this), _amount);
        _compoundInterest(_tokenAddress, msg.sender, true);
        token.depositBalances[msg.sender] += _amount;
        token.depositTimestamps[msg.sender] = block.timestamp;
    }

    // Withdraw function
    function withdraw(address _tokenAddress, uint256 _amount) external {
        TokenInfo storage token = tokens[_tokenAddress];
        require(token.depositBalances[msg.sender] >= _amount, "Insufficient balance");

        _compoundInterest(_tokenAddress, msg.sender, true);
        token.depositBalances[msg.sender] -= _amount;
        token.token.transfer(msg.sender, _amount);
    }

    // Borrow function
    function borrow(address _tokenAddress, uint256 _amount) external {
        TokenInfo storage token = tokens[_tokenAddress];
        uint256 maxBorrowValue = token.depositBalances[msg.sender] * token.maxLTV / 100;
        require(_amount <= maxBorrowValue, "Borrow amount exceeds max LTV");

        _compoundInterest(_tokenAddress, msg.sender, false);
        token.borrowBalances[msg.sender] += _amount;
        token.borrowTimestamps[msg.sender] = block.timestamp;
        token.token.transfer(msg.sender, _amount);
    }

    // Repay function
    function repay(address _tokenAddress, uint256 _amount) external {
        TokenInfo storage token = tokens[_tokenAddress];
        require(token.borrowBalances[msg.sender] >= _amount, "Repay amount exceeds borrow");

        _compoundInterest(_tokenAddress, msg.sender, false);
        token.borrowBalances[msg.sender] -= _amount;
        token.token.transferFrom(msg.sender, address(this), _amount);
    }

    // Check for liquidation
    function checkLiquidation(address _tokenAddress, address _user) public view returns (bool) {
        TokenInfo storage token = tokens[_tokenAddress];
        uint256 collateralValue = token.depositBalances[_user];
        uint256 borrowValue = token.borrowBalances[_user];
        return borrowValue >= (collateralValue * token.liquidationThreshold) / 100;
    }

    // Liquidation function
    function liquidate(address _tokenAddress, address _user) external {
        TokenInfo storage token = tokens[_tokenAddress];
        require(checkLiquidation(_tokenAddress, _user), "Position not subject to liquidation");

        uint256 collateralValue = token.depositBalances[_user];
        uint256 debtValue = token.borrowBalances[_user];
        uint256 discountedCollateral = collateralValue * (100 - token.liquidationPenalty) / 100;
        
        require(debtValue <= discountedCollateral, "Not enough collateral to cover the debt");

        uint256 collateralToLiquidate = debtValue * 100 / (100 - token.liquidationPenalty);
        token.depositBalances[_user] -= collateralToLiquidate;
        token.token.transfer(msg.sender, collateralToLiquidate);
        token.borrowBalances[_user] -= debtValue;
    }

    function swapGruxFiToGruxFiReward(uint256 amount) external {
        require(GruxFi.balanceOf(msg.sender) >= amount, "Insufficient GruxFi balance");
        GruxFi.transferFrom(msg.sender, address(this), amount);
        GruxFiReward.swapTokensForTokens(amount, msg.sender);
    }

    function swapRewardToGruxFi(uint256 amount) external {
        require(GruxFiReward.balanceOf(msg.sender) >= amount, "Insufficient GruxFiReward balance");
        GruxFiReward.transferFrom(msg.sender, address(this), amount);
        GruxFi.swapTokensForTokens(amount, msg.sender);
    }

    function activateBaseCurrency(address _GruxFi) external onlyOwner {
        require(address(GruxFi) == address(0), "GruxFi already set");
        GruxFi = IERC20(_GruxFi);
    }

    function establishRewardAsset(address _GruxFiReward) external onlyOwner {
        require(address(GruxFiReward) == address(0), "GruxFiReward already set");
        GruxFiReward = IERC20(_GruxFiReward);
    }

        function claimGruxFiRewards(address _tokenAddress) external {
        TokenInfo storage token = tokens[_tokenAddress];
        require(token.rewardBalances[msg.sender] > 0, "No rewards available");
        uint256 rewardAmount = token.rewardBalances[msg.sender];
        token.rewardBalances[msg.sender] = 0;
        GruxFiReward.transfer(msg.sender, rewardAmount);
    }

    // Toggle pool activity
    function toggleDepositWithdrawActivity() external onlyOwner {
        isDepositWithdrawActive = !isDepositWithdrawActive;
    }

    function toggleBorrowActivity() external onlyOwner {
        isBorrowActive = !isBorrowActive;
    }
    function _compoundInterest(address _tokenAddress, address _user, bool isDepositor) internal {
        TokenInfo storage token = tokens[_tokenAddress];
        uint256 principal = isDepositor ? token.depositBalances[_user] : token.borrowBalances[_user];
        uint256 rate = isDepositor ? token.depositAPY : token.borrowAPY;
        uint256 timeElapsed = block.timestamp - (isDepositor ? token.depositTimestamps[_user] : token.borrowTimestamps[_user]);
        
        if (timeElapsed > 0 && principal > 0) {
            uint256 interest = principal * rate / 100 * timeElapsed / 365 days;
            if (isDepositor) {
                token.depositBalances[_user] += interest;
            } else {
                token.borrowBalances[_user] += interest;
            }
        }
    }
}