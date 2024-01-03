pragma solidity 0.6.12;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Initializable.sol";
import "./IERC20.sol";

import "./BaseToken.sol";

contract Vault is OwnableUpgradeSafe {
    using SafeMath for uint256;

    BaseToken public BASE;
    IERC20    public stakeToken;

    uint256 public enrollmentPeriodStartTimestamp;
    uint256 public enrollmentPeriodDuration;
    uint256 public vestingStartTimestamp;
    uint256 public vestingDuration;
    uint256 public maxStaked;

    uint256 public totalStaked;
    uint256 public totalRewardShares;
    mapping(address => uint256) public staked;
    mapping(address => uint256) public sharesWithdrawnByUser;
    mapping(address => bool)    public unstaked;

    event Stake(address indexed user, uint256 newAmount, uint256 totalAmount);
    event Unstake(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 tokensWithdrawnThisTime, uint256 totalSharesWithdrawnByUser);
    event RescueFunds(address token, address recipient, uint256 amount);
    event AddRewards(uint256 amountAdded, uint256 totalRewardTokens);
    event RemoveRewards(uint256 amountRemoved, uint256 totalRewardTokens);

    function initialize()
        public
        initializer
    {
        __Ownable_init();
    }

    /**
     * User methods
     */

    function stake(uint256 tokens)
        public
    {
        require(now > enrollmentPeriodStartTimestamp, "too soon");
        require(now < enrollmentPeriodStartTimestamp + enrollmentPeriodDuration, "too late");

        uint256 amount = stakeTokenIsBASE() ? tokensToShares(tokens) : tokens;
        require(maxStaked == 0 || totalStaked + amount < maxStaked, "full");

        staked[msg.sender] = staked[msg.sender].add(amount);
        totalStaked = totalStaked.add(amount);

        bool ok = stakeToken.transferFrom(msg.sender, address(this), tokens);
        require(ok, "transfer");

        emit Stake(msg.sender, amount, staked[msg.sender]);
    }

    function withdrawRewards()
        public
    {
        require(now > vestingStartTimestamp, "too soon");

        (uint256 tokens, uint256 shares) = withdrawable(msg.sender);
        require(tokens > 0, "no tokens");
        require(shares > 0, "no shares");

        sharesWithdrawnByUser[msg.sender] = sharesWithdrawnByUser[msg.sender].add(shares);

        bool ok = BASE.transfer(msg.sender, tokens);
        require(ok, "transfer reward");

        emit Withdraw(msg.sender, tokens, sharesWithdrawnByUser[msg.sender]);
    }

    function unstake()
        public
    {
        require(now > vestingStartTimestamp + vestingDuration, "too soon");

        require(unstaked[msg.sender] == false, "already unstaked");
        unstaked[msg.sender] = true;

        (uint256 tokens, uint256 shares) = withdrawable(msg.sender);
        require(shares > 0, "no stake");

        sharesWithdrawnByUser[msg.sender] = sharesWithdrawnByUser[msg.sender].add(shares);
        emit Withdraw(msg.sender, tokens, sharesWithdrawnByUser[msg.sender]);

        bool ok = BASE.transfer(msg.sender, tokens);
        require(ok, "transfer reward");

        uint256 amount = stakeTokenIsBASE() ? sharesToTokens(staked[msg.sender]) : staked[msg.sender];
        ok = stakeToken.transfer(msg.sender, amount);
        require(ok, "transfer deposit");

        emit Unstake(msg.sender, staked[msg.sender]);
    }

    /**
     * Getters
     */

    function vaultInfo(address user)
        public
        view
        returns (
            uint256 _enrollmentPeriodStartTimestamp,
            uint256 _enrollmentPeriodDuration,
            uint256 _vestingStartTimestamp,
            uint256 _vestingDuration,
            uint256 _maxStaked,
            uint256 _totalTokensStaked,
            uint256 _tokensStakedByUser,
            uint256 _totalRewardTokens,
            uint256 _tokensWithdrawableByUser,
            uint256 _tokensWithdrawnByUser
        )
    {
        _enrollmentPeriodStartTimestamp = enrollmentPeriodStartTimestamp;
        _enrollmentPeriodDuration = enrollmentPeriodDuration;
        _vestingStartTimestamp = vestingStartTimestamp;
        _vestingDuration = vestingDuration;
        _maxStaked = stakeTokenIsBASE() ? sharesToTokens(maxStaked) : maxStaked;
        _totalTokensStaked = stakeTokenIsBASE() ? sharesToTokens(totalStaked) : totalStaked;
        _tokensStakedByUser = stakeTokenIsBASE() ? sharesToTokens(staked[user]) : staked[user];
        _totalRewardTokens = sharesToTokens(totalRewardShares);
        (_tokensWithdrawableByUser, ) = withdrawable(user);
        _tokensWithdrawnByUser = sharesToTokens(sharesWithdrawnByUser[user]);
        return (
            _enrollmentPeriodStartTimestamp,
            _enrollmentPeriodDuration,
            _vestingStartTimestamp,
            _vestingDuration,
            _maxStaked,
            _totalTokensStaked,
            _tokensStakedByUser,
            _totalRewardTokens,
            _tokensWithdrawableByUser,
            _tokensWithdrawnByUser
        );
    }

    function withdrawable(address user)
        public
        view
        returns (uint256 tokens, uint256 shares)
    {
        uint256 secondsIntoVesting = vestingStartTimestamp >= now
                                        ? 0
                                        : now.sub(vestingStartTimestamp);
        if (secondsIntoVesting == 0) {
            return (0, 0);
        } else if (totalStaked == 0) {
            return (0, 0);
        }

        if (secondsIntoVesting > vestingDuration) {
            secondsIntoVesting = vestingDuration;
        }

        uint256 userRewardShares = totalRewardShares.mul(staked[user]).div(totalStaked);
        uint256 unlockedShares = userRewardShares.mul(secondsIntoVesting).div(vestingDuration).sub(sharesWithdrawnByUser[user]);
        uint256 unlockedTokens = sharesToTokens(unlockedShares);
        return (unlockedTokens, unlockedShares);
    }

    /**
     * Admin
     */

    function setupVault(
        BaseToken BASE_,
        IERC20 stakeToken_,
        uint256 maxStaked_,
        uint256 enrollmentPeriodStartTimestamp_,
        uint256 enrollmentPeriodDuration_,
        uint256 vestingStartTimestamp_,
        uint256 vestingDuration_
    )
        public
        onlyOwner
    {
        require(enrollmentPeriodDuration_ > 0, "enrollmentPeriodDuration is 0");
        require(vestingDuration_ > 0, "vestingDuration is 0");

        BASE = BASE_;
        stakeToken = stakeToken_;
        maxStaked = maxStaked_;
        enrollmentPeriodStartTimestamp = enrollmentPeriodStartTimestamp_;
        enrollmentPeriodDuration = enrollmentPeriodDuration_;
        vestingStartTimestamp = vestingStartTimestamp_;
        vestingDuration = vestingDuration_;
    }

    function addRewards(uint256 tokens)
        public
        onlyOwner
    {
        totalRewardShares = totalRewardShares.add(tokensToShares(tokens));
        bool ok = BASE.transferFrom(msg.sender, address(this), tokens);
        require(ok, "transfer");
        emit AddRewards(tokens, sharesToTokens(totalRewardShares));
    }

    function removeRewards(uint256 tokens)
        public
        onlyOwner
    {
        totalRewardShares = totalRewardShares.sub(tokensToShares(tokens));
        bool ok = BASE.transfer(msg.sender, tokens);
        require(ok, "transfer");
        emit RemoveRewards(tokens, sharesToTokens(totalRewardShares));
    }

    function adminRescueFunds(address token, address recipient, uint256 amount)
        public
        onlyOwner
    {
        emit RescueFunds(token, recipient, amount);

        bool ok = IERC20(token).transfer(recipient, amount);
        require(ok, "transfer");
    }

    /**
     * Util
     */

    function stakeTokenIsBASE()
        private
        view
        returns (bool)
    {
        return address(stakeToken) == address(BASE);
    }

    function sharesToTokens(uint256 shares)
        public
        view
        returns (uint256)
    {
        return shares.mul(BASE.totalSupply()).div(BASE.totalShares());
    }

     function tokensToShares(uint256 tokens)
        public
        view
        returns (uint256)
    {
        return tokens.mul(BASE.totalShares().div(BASE.totalSupply()));
    }
}