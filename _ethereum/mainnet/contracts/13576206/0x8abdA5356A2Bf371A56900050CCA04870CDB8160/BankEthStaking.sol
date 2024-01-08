pragma solidity ^ 0.8.4;

import "./IBankEth.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeMathUint.sol";
import "./SafeMathInt.sol";
import "./ReentrancyGuard.sol";
import "./IUniswapV2Router.sol";

contract BankEthStaking is Ownable, ReentrancyGuard {
    uint256 constant REWARD_MAG = 10000;

    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    event BankEthStaked(address staker, uint256 amount, uint256 duration);

    event ReflectionsClaimed(address staker, uint256 amount);
    event StakingReleased(address staker, uint256 amount);

    struct Stake {
        uint256 nonce;
        address staker;
        address pool;
        uint256 contribution;
        uint256 bonus;
        uint256 end;
        bool released;
    }

    struct Tier {
        uint256 daysToStake;
        uint256 rewardRate;
        bool active;
    }

    uint256 constant internal magnitude = 2 ** 128;
    uint256 internal magnifiedDividendPerShare;
    mapping(address => int256)internal magnifiedDividendCorrections;
    mapping(address => uint256)internal withdrawnDividends;
    uint256 public totalDividendsDistributed;
    uint256 public totalDividendBalance;
    mapping(address => uint256) private dividendBalances;

    uint256 stakeNonce = 1;

    mapping(address => uint256[]) userStakes;
    mapping(uint256 => Stake) stakes;

    uint256[] tiers;
    mapping(uint256 => Tier) rewardRates;

    IBankEth public bankEth;
    IUniswapV2Router02 public uniswapV2Router;

    constructor() {
        bankEth = IBankEth(0xBE0C826f17680d8Da620855bE89DD6544C034cA1);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
    }

    function addStakingTokens(uint256 tokenAmount) external onlyOwner {
        require(bankEth.balanceOf(msg.sender) >= tokenAmount, "BankEthStaking: Insufficient BankEth Balance");
        bankEth.transferFrom(msg.sender, address(this), tokenAmount);
        incrementBalance(owner(), tokenAmount);
    }

    function removeStakingTokens(uint256 tokenAmount) external onlyOwner {
        require(dividendBalanceOf(msg.sender) >= tokenAmount, "BankEthStaking: Insufficient BankEth Balance");
        bankEth.transfer(msg.sender, tokenAmount);
        decrementBalance(msg.sender, tokenAmount);
    }

    function addTier(uint256 daysToStake, uint256 rate) external onlyOwner {
        require(!rewardRates[daysToStake].active, "BankEthStaking: Tier is already populated");
        Tier memory tier = Tier(daysToStake, rate, true);
        tiers.push(daysToStake);
        rewardRates[daysToStake] = tier;
    }

    function removeTier(uint256 daysToStake) external onlyOwner {
        require(rewardRates[daysToStake].active, "BankEthStaking: Tier is not populated");
        rewardRates[daysToStake].active = false;

        for (uint256 i = 0; i < tiers.length; i++) {
            if (tiers[i] == daysToStake) {
                tiers[i] = tiers[tiers.length - 1];
                tiers.pop();
                break;
            }
        }
    }

    function getTiers() external view returns(Tier[] memory _tiers) {
        _tiers = new Tier[](tiers.length);
        for (uint256 i = 0; i < tiers.length; i++) {
            _tiers[i] = rewardRates[tiers[i]];
        }
    }

    function stakeForEth(uint256 tokenAmount, uint256 _days) public {
        require(bankEth.balanceOf(msg.sender) >= tokenAmount, "BankEthStaking: Insufficient BankEth Balance");
        require(rewardRates[_days].active, "BankEthStaking: Tier is not populated");
        bankEth.transferFrom(msg.sender, address(this), tokenAmount);

        uint256 bonus = calculateBonus(tokenAmount, _days);
        uint256 totalStake = tokenAmount.add(bonus);
        uint256 releaseTime = block.timestamp.add(_days.mul(1 days));

        Stake memory newStake = Stake(
            stakeNonce,
            msg.sender,
            address(0),
            tokenAmount,
            bonus,
            releaseTime,
            false
        );

        userStakes[msg.sender].push(stakeNonce);
        stakes[stakeNonce] = newStake;
        incrementBalance(msg.sender, totalStake);
        decrementBalance(owner(), bonus);
        stakeNonce = stakeNonce.add(1);
    }

    function releaseEthStake(uint256 _stakeNonce) public nonReentrant {
        Stake memory stakeInfo = stakes[_stakeNonce];
        require(stakeInfo.staker == msg.sender, "BankEthStaking: Caller is not the staker");
        require(block.timestamp > stakeInfo.end, "BankEthStaking: Stake is not releasable");
        require(!stakeInfo.released, "BankEthStaking: Staking is already released");
        receiveRewards();

        uint256 totalStake = stakeInfo.bonus.add(stakeInfo.contribution);
        decrementBalance(msg.sender, totalStake);
        incrementBalance(owner(), stakeInfo.bonus);
        bankEth.transfer(msg.sender, stakeInfo.contribution);
        stakeInfo.released = true;
    }

    function userStakingInfo(address account)public view returns(Stake[] memory _stakes) {
        uint256[] storage userStakeNonces = userStakes[account];
        _stakes = new Stake[](userStakeNonces.length);
        for (uint i = 0; i < userStakeNonces.length; i ++) {
            uint256 _stakeNonce = userStakeNonces[i];
            Stake storage stake = stakes[_stakeNonce];
            _stakes[i] = stake;
        }
        return _stakes;
    }

    function calculateBonus(uint256 tokenAmount, uint256 _days) public view returns(uint256) {
        uint256 rate = rewardRates[_days].rewardRate;
        return tokenAmount.mul(rate).div(REWARD_MAG);
    }

    function distributeDividends()public payable {
        require(totalDividendBalance > 0);
        if (msg.value > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add((msg.value).mul(magnitude) / totalDividendBalance);
            totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
        }
    }
    
    function withdrawDividend(bool reinvest, uint256 minTokens) external {
        _withdrawDividend(msg.sender, reinvest, minTokens);
    }

    function _withdrawDividend(address account, bool reinvest, uint256 minTokens) internal {
        receiveRewards();

        if (reinvest) {
            withdrawTokens(account, minTokens);
        } else {
            withdrawEth(account);
        }
    }

    function withdrawEth(address account) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(account);
        if (_withdrawableDividend > 0) {

            withdrawnDividends[account] = withdrawnDividends[account].add(_withdrawableDividend);
            //   emit DividendWithdrawn(user, _withdrawableDividend, to);
            (bool success,) = account.call{value: _withdrawableDividend}("");
            if(!success) {
                withdrawnDividends[account] = withdrawnDividends[account].sub(_withdrawableDividend);
                return 0;
            }
            return _withdrawableDividend;
        }
        return 0;
    }

    function withdrawTokens(address account, uint256 minTokens) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(account);
        if (_withdrawableDividend > 0) {
            swapEthForTokens(_withdrawableDividend, minTokens, account);
            return _withdrawableDividend;
        }
        return 0;
    }

    function swapEthForTokens(uint256 ethAmount, uint256 minTokens, address account) internal returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(bankEth);
        
        uint256 balanceBefore = bankEth.balanceOf(account);
        
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            minTokens,
            path,
            account,
            block.timestamp
        );
        
        uint256 tokenAmount = bankEth.balanceOf(account).sub(balanceBefore);
        return tokenAmount;
    }
    
    function dividendOf(address _owner) public view returns(uint256) {
        return withdrawableDividendOf(_owner);
    }
    
    function withdrawableDividendOf(address _owner) public view returns(uint256) {
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
    }

    function withdrawnDividendOf(address _owner) public view returns(uint256) {
        return withdrawnDividends[_owner];
    }

    function accumulativeDividendOf(address _owner) public view returns(uint256) {
        return magnifiedDividendPerShare.mul(dividendBalanceOf(_owner)).toInt256Safe()
        .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
    }

    function dividendBalanceOf(address account) public view virtual returns (uint256) {
        return dividendBalances[account];
    }

    function incrementBalance(address staker, uint256 tokenAmount) internal {
        totalDividendBalance = totalDividendBalance.add(tokenAmount);
        dividendBalances[staker] = dividendBalances[staker].add(tokenAmount);
        magnifiedDividendCorrections[staker] = magnifiedDividendCorrections[staker]
        .sub( (magnifiedDividendPerShare.mul(tokenAmount)).toInt256Safe() );
    }

    function decrementBalance(address staker, uint256 tokenAmount) internal {
        dividendBalances[staker] = dividendBalances[staker].sub(tokenAmount);
        totalDividendBalance = totalDividendBalance.sub(tokenAmount);
        magnifiedDividendCorrections[staker] = magnifiedDividendCorrections[staker]
        .add((magnifiedDividendPerShare.mul(tokenAmount)).toInt256Safe() );
    }

    function receiveRewards() internal {
        if (bankEth.withdrawableDividendOf(address(this)) > 0) {
            bankEth.claim(false, 0);
        }
    }

    function userInfo(address account) public view returns(uint256 withdrawableDividend, uint256 withdrawnDividend, uint256 currentStake) {
        withdrawableDividend = withdrawableDividendOf(account);
        withdrawnDividend = withdrawnDividendOf(account);
        currentStake = dividendBalanceOf(account);
    }

    function pendingDividends(address account) public view returns(uint256) {
        uint256 withdrawable = bankEth.withdrawableDividendOf(address(this));
        uint256 _magnifiedDividendPerShare = magnifiedDividendPerShare;

        if (withdrawable > 0) {
            _magnifiedDividendPerShare = _magnifiedDividendPerShare.add((withdrawable).mul(magnitude) / totalDividendBalance);
        } 
        
        uint256 accumulate = _magnifiedDividendPerShare.mul(dividendBalanceOf(account)).toInt256Safe()
        .add(magnifiedDividendCorrections[account]).toUint256Safe() / magnitude;

        return accumulate.sub(withdrawnDividends[account]);
    }

    function transferOwnership(address newOwner) public virtual override onlyOwner nonReentrant {
        address prevOwner = owner();
        super.transferOwnership(newOwner);
        receiveRewards();
        withdrawEth(prevOwner);
        uint256 tokenAmount = dividendBalanceOf(prevOwner);
        decrementBalance(prevOwner, tokenAmount);
        incrementBalance(newOwner, tokenAmount);
    }

    receive()external payable {
        distributeDividends();
    }
}