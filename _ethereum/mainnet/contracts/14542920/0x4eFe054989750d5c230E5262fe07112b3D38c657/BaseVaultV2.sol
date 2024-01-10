pragma solidity ^0.6.0;

import "./Math.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./Initializable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC20Vault.sol";
import "./IVaultCore.sol";
import "./IVaultTransfers.sol";
import "./IController.sol";
import "./IStrategy.sol";

abstract contract BaseVaultV2 is
    IVaultCore,
    IVaultTransfers,
    ERC20Vault,
    Ownable,
    ReentrancyGuard,
    Pausable,
    Initializable
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => uint256) public rewardsPerTokensStored;
    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewardRates;
    mapping(address => mapping(address => uint256)) public rewards;
    mapping(address => uint256) public lastUpdateTimePerToken;
    mapping(address => uint256) public periodFinishPerToken;
    EnumerableSet.AddressSet internal validTokens;
    uint256 public rewardsDuration;
    address public rewardsDistribution;
    address public trustworthyEarnCaller;
    IERC20 public stakingToken;
    IController internal _controller;

    event RewardAdded(address what, uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address what, address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);

    constructor(string memory _name, string memory _symbol)
        public
        ERC20Vault(_name, _symbol)
    {
        trustworthyEarnCaller = _msgSender();
    }

    function _configure(
        address _initialToken,
        address _initialController,
        address _governance,
        uint256 _rewardsDuration,
        address[] memory _rewardsTokens,
        string memory _namePostfix,
        string memory _symbolPostfix
    )
        internal
    {
        setController(_initialController);
        transferOwnership(_governance);
        stakingToken = IERC20(_initialToken);
        rewardsDuration = _rewardsDuration;
        _name = string(abi.encodePacked(_name, _namePostfix));
        _symbol = string(abi.encodePacked(_symbol, _symbolPostfix));
        for (uint256 i = 0; i < _rewardsTokens.length; i++) {
            validTokens.add(_rewardsTokens[i]);
        }
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address _account) {
        _updateAllRewards(_account);
        _;
    }

    modifier updateRewardPerToken(address _rewardToken, address _account) {
        _updateReward(_rewardToken, _account);
        _;
    }

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "!rewardsDistribution");
        _;
    }

    modifier onlyValidToken(address _rewardToken) {
        require(validTokens.contains(_rewardToken), "!valid");
        _;
    }

    /* ========== DEPOSIT FUNCTIONS ========== */

    function deposit(uint256 amount)
        external
        override
        nonReentrant
        whenNotPaused
        updateReward(msg.sender)
    {
        _deposit(msg.sender, amount);
    }

    function depositFor(uint256 _amount, address _for)
        external
        override
        nonReentrant
        whenNotPaused
        updateReward(_for)
    {
        _deposit(_for, _amount);
    }

    function depositAll()
        external
        override
        nonReentrant
        whenNotPaused
        updateReward(msg.sender)
    {
        uint256 _balance = stakingToken.balanceOf(msg.sender);
        require(_balance > 0, "0balance");
        _deposit(msg.sender, _balance);
    }

    function _deposit(address _from, uint256 _amount)
        internal
        virtual
        returns (uint256)
    {
        require(_amount > 0, "Cannot stake 0");
        address strategy = IController(_controller).strategies(address(stakingToken));
        stakingToken.safeTransferFrom(msg.sender, strategy, _amount);
        IStrategy(strategy).deposit();
        _mint(_from, _amount);
        emit Staked(_from, _amount);
        return _amount;
    }

    /* ========== WITHDRAWAL FUNCTIONS ========== */

    function withdraw(uint256 _amount) external override {
        withdraw(_amount, true);
    }

    function withdrawAll() external override {
        withdraw(_balances[msg.sender], true);
    }

    function withdraw(uint256 _amount, bool _claimUnderlying)
        public
        nonReentrant
        updateReward(msg.sender)
    {
        _getRewardAll(_claimUnderlying);
        _withdraw(_amount);
    }

    function _withdraw(uint256 _amount) private returns (uint256) {
        return _withdrawFrom(msg.sender, _amount);
    }

    function _withdrawFrom(address _from, uint256 _amount)
        private
        returns (uint256)
    {
        require(_amount > 0, "Cannot withdraw 0");
        _burn(msg.sender, _amount);
        address strategyAddress = IController(_controller).strategies(address(stakingToken));
        uint256 amountOnVault = stakingToken.balanceOf(address(this));
        if (amountOnVault < _amount) {
            IStrategy(strategyAddress).withdraw(_amount.sub(amountOnVault));
        }
        stakingToken.safeTransfer(_from, _amount);
        emit Withdrawn(_from, _amount);
        return _amount;
    }

    /* ========== REWARD GETTING FUNCTIONS ========== */

    function getReward(bool _claimUnderlying)
        external
        nonReentrant
        updateReward(msg.sender)
    {
        _getRewardAll(_claimUnderlying);
    }

    function _getRewardAll(bool _claimUnderlying) private {
        for (uint256 i = 0; i < validTokens.length(); i++) {
            _getReward(
                _claimUnderlying,
                msg.sender,
                validTokens.at(i),
                address(stakingToken)
            );
        }
    }

    function _getReward(
        bool _claimUnderlying,
        address _for,
        address _rewardToken,
        address _stakingToken
    )
        internal
        virtual;

    function claimRewardsFromStrategy() external override {
        require(_msgSender() == trustworthyEarnCaller, "!trustworthyEarnCaller");
        _controller.getRewardStrategy(address(stakingToken));
        for (uint256 i = 0; i < validTokens.length(); i++) {
            _controller.claim(address(stakingToken), validTokens.at(i));
        }
    }

    function notifyRewardAmount(address _rewardToken, uint256 _reward)
        external
        virtual
        onlyRewardsDistribution
        onlyValidToken(_rewardToken)
        updateRewardPerToken(_rewardToken, address(0))
    {
        if (block.timestamp >= periodFinishPerToken[_rewardToken]) {
            rewardRates[_rewardToken] = _reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinishPerToken[_rewardToken].sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRates[_rewardToken]);
            rewardRates[_rewardToken] = _reward.add(leftover).div(rewardsDuration);
        }
        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = IERC20(_rewardToken).balanceOf(address(this));
        require(
            rewardRates[_rewardToken] <= balance.div(rewardsDuration),
            "Provided reward too high"
        );
        lastUpdateTimePerToken[_rewardToken] = block.timestamp;
        periodFinishPerToken[_rewardToken] = block.timestamp.add(rewardsDuration);
        emit RewardAdded(_rewardToken, _reward);
    }

    function setTrustworthyEarnCaller(address _who) external onlyOwner {
        trustworthyEarnCaller = _who;
    }

    function setRewardsDistribution(address _rewardsDistribution) external onlyOwner {
        rewardsDistribution = _rewardsDistribution;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        bool finished = true;
        for (uint256 i = 0; i < validTokens.length(); ++i) {
            if (block.timestamp <= periodFinishPerToken[validTokens.at(i)]) {
                finished = false;
            }
            require(finished, "!periodFinishPerToken");
        }
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    function addRewardToken(address _rewardToken) external onlyOwner {
        require(validTokens.add(_rewardToken), "!add");
    }

    function removeRewardToken(address _rewardToken) external onlyOwner {
        require(validTokens.remove(_rewardToken), "!remove");
    }

    function isTokenValid(address _rewardToken) external view returns (bool) {
        return validTokens.contains(_rewardToken);
    }

    function getRewardToken(uint256 _index) external view returns (address) {
        return validTokens.at(_index);
    }

    function getRewardTokensCount() external view returns (uint256) {
        return validTokens.length();
    }

    function userReward(address _account, address _token)
        external
        view
        onlyValidToken(_token)
        returns (uint256)
    {
        return rewards[_account][_token];
    }

    function potentialRewardReturns(
        address _rewardsToken,
        uint256 _duration,
        address _account
    )
        external
        view
        returns (uint256)
    {
        uint256 _rewardsAmount = _balances[_account]
        .mul(
            _rewardPerTokenForDuration(_rewardsToken, _duration).sub(
                userRewardPerTokenPaid[_rewardsToken][_account]
            )
        )
        .div(1e18)
        .add(rewards[_account][_rewardsToken]);
        return _rewardsAmount;
    }

    function token() external view override returns (address) {
        return address(stakingToken);
    }

    function controller() external view override returns (address) {
        return address(_controller);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        public
        override
        returns (bool)
    {
        _updateAllRewards(sender);
        _updateAllRewards(recipient);
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        address sender = _msgSender();
        _updateAllRewards(sender);
        _updateAllRewards(recipient);
        _transfer(sender, recipient, amount);
        return true;
    }

    /// @notice Usual setter with check if passet param is new
    /// @param _newController New value
    function setController(address _newController) public onlyOwner {
        require(address(_controller) != _newController, "!new");
        _controller = IController(_newController);
    }

    function lastTimeRewardApplicable(address _rewardToken) public view returns (uint256) {
        return Math.min(block.timestamp, periodFinishPerToken[_rewardToken]);
    }

    function balance() public view override returns (uint256) {
        IStrategy strategy = IStrategy(
            _controller.strategies(address(stakingToken))
        );
        return stakingToken.balanceOf(address(this)).add(strategy.balanceOf());
    }

    function rewardPerToken(address _rewardToken)
        public
        view
        onlyValidToken(_rewardToken)
        returns (uint256)
    {
        if (_totalSupply == 0) {
            return rewardsPerTokensStored[_rewardToken];
        }
        return
        rewardsPerTokensStored[_rewardToken].add(
            lastTimeRewardApplicable(_rewardToken)
            .sub(lastUpdateTimePerToken[_rewardToken])
            .mul(rewardRates[_rewardToken])
            .mul(1e18)
            .div(_totalSupply)
        );
    }

    function earned(address _rewardToken, address _account)
        public
        view
        virtual
        onlyValidToken(_rewardToken)
        returns (uint256)
    {
        return
        _balances[_account]
        .mul(
            rewardPerToken(_rewardToken).sub(
                userRewardPerTokenPaid[_rewardToken][_account]
            )
        )
        .div(1e18)
        .add(rewards[_account][_rewardToken]);
    }

    function _updateAllRewards(address _account) internal virtual {
        for (uint256 i = 0; i < validTokens.length(); i++) {
            _updateReward(validTokens.at(i), _account);
        }
    }

    function _updateReward(address _what, address _account) internal virtual {
        rewardsPerTokensStored[_what] = rewardPerToken(_what);
        lastUpdateTimePerToken[_what] = lastTimeRewardApplicable(_what);
        if (_account != address(0)) {
            rewards[_account][_what] = earned(_what, _account);
            userRewardPerTokenPaid[_what][_account] = rewardsPerTokensStored[
            _what
            ];
        }
    }

    function _rewardPerTokenForDuration(
        address _rewardsToken,
        uint256 _duration
    ) internal view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardsPerTokensStored[_rewardsToken];
        }
        return
        rewardsPerTokensStored[_rewardsToken].add(
            _duration.mul(rewardRates[_rewardsToken]).mul(1e18).div(
                _totalSupply
            )
        );
    }
}
