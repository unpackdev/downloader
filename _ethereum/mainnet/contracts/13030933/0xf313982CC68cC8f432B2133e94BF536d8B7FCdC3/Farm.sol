// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./IUniswapV2Pair.sol";

contract Farm is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* -----------     LiquidityMining START----------------------- */

    //bool public initialized;
    address[] public tokenAddresses;

    struct RewardToken {
        uint256 initReward;
        uint256 startTime;
        uint256 rewardRate;
        uint256 duration;
        uint256 periodFinish;
        mapping(address => uint256) userRewardPerTokenPaid;
        mapping(address => uint256) rewards;
        uint256 rewardPerTokenStored;
        uint256 lastUpdateTime;
        bool initialized;
    }
    mapping(address => RewardToken) public rewardTokens;

    bytes32 public constant COLLECTION = bytes32(keccak256("COLLECTION_ROLE"));

    /**
     * @dev           Initialize contract.
     * @param _rewardToken  The address
     * @param _initReward Initial reward
     */
    function initialize(
        address _rewardToken,
        uint256 _initReward,
        uint256 _startTime,
        uint256 _duration
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _rewardToken != address(0),
            "StakingRewards: rewardToken cannot be null"
        );

        require(_initReward != 0, "StakingRewards: initreward cannot be null");
        require(_duration != 0, "StakingRewards: duration cannot be null");
        require(
            rewardTokens[_rewardToken].initialized == false,
            "already initialized"
        );

        RewardToken storage rewardToken = rewardTokens[_rewardToken];
        rewardToken.initReward = _initReward;
        rewardToken.startTime = _startTime;
        rewardToken.initialized = true;

        tokenAddresses.push(_rewardToken);
        rewardToken.duration = (_duration * 24 hours);

        _notifyRewardAmount(_rewardToken, _initReward);
    }

    uint256 private _totalSupply;
    mapping(address => uint256) public _balances;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    function updateReward(address account) internal {
        RewardToken storage rewardTokenStruct;
        uint256 len = tokenAddresses.length;
        for (uint256 i = 0; i < len; i++) {
            rewardTokenStruct = rewardTokens[tokenAddresses[i]];
            rewardTokenStruct.rewardPerTokenStored = rewardPerToken(
                tokenAddresses[i]
            );
            rewardTokenStruct.lastUpdateTime = lastTimeRewardApplicable(
                tokenAddresses[i]
            );
            if (account != address(0)) {
                rewardTokenStruct.rewards[account] = earned(
                    tokenAddresses[i],
                    account
                );
                rewardTokenStruct.userRewardPerTokenPaid[
                    account
                ] = rewardTokenStruct.rewardPerTokenStored;
            }
        }
    }

    function getRewardTokens() public view returns (address[] memory) {
        return tokenAddresses;
    }

    function lastTimeRewardApplicable(address rewardTokenAddress)
        public
        view
        returns (uint256)
    {
        return
            Math.min(
                block.timestamp,
                rewardTokens[rewardTokenAddress].periodFinish
            );
    }

    function rewardPerToken(address rewardTokenAddress)
        public
        view
        returns (uint256)
    {
        RewardToken storage rewardTokenStruct = rewardTokens[
            rewardTokenAddress
        ];
        if (_totalSupply == 0) {
            return rewardTokenStruct.rewardPerTokenStored;
        }
        return
            rewardTokenStruct.rewardPerTokenStored.add(
                lastTimeRewardApplicable(rewardTokenAddress)
                    .sub(rewardTokenStruct.lastUpdateTime)
                    .mul(rewardTokenStruct.rewardRate)
                    .mul(1e18)
                    .div(_totalSupply)
            );
    }

    function earned(address rewardTokenAddress, address account)
        public
        view
        returns (uint256)
    {
        RewardToken storage rewardTokenStruct = rewardTokens[
            rewardTokenAddress
        ];
        uint256 amount = _balances[account]
            .mul(
                rewardPerToken(rewardTokenAddress).sub(
                    rewardTokenStruct.userRewardPerTokenPaid[account]
                )
            )
            .div(1e36)
            .add(rewardTokenStruct.rewards[account]);

        return amount;
    }

    function claimReward(address rewardTokenAddress) external nonReentrant {
        updateReward(msg.sender);

        RewardToken storage rewardTokenStruct = rewardTokens[
            rewardTokenAddress
        ];
        uint256 reward = rewardTokenStruct.rewards[msg.sender];

        require(reward > 0, "you have no reward");

        IERC20 token = IERC20(rewardTokenAddress);

        require(token.transfer(msg.sender, reward), "Transfer error!");

        rewardTokenStruct.rewards[msg.sender] = 0;
        //token.transferFrom(address(this), msg.sender, reward);
        emit RewardPaid(msg.sender, reward);
    }

    function getReward(address rewardTokenAddress) internal nonReentrant {
        RewardToken storage rewardTokenStruct = rewardTokens[
            rewardTokenAddress
        ];
        uint256 reward = rewardTokenStruct.rewards[msg.sender];

        require(reward > 0, "you have no reward");

        IERC20 token = IERC20(rewardTokenAddress);

        require(token.transfer(msg.sender, reward), "Transfer error!");

        rewardTokenStruct.rewards[msg.sender] = 0;
        //token.transferFrom(address(this), msg.sender, reward);
        emit RewardPaid(msg.sender, reward);
    }

    function emergencyWithdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "StakingRewards: Cannot withdraw 0");
        require(
            _balances[msg.sender] >= amount,
            "Insufficient amount for emergency Withdraw"
        );

        //updateReward(msg.sender);

        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _token.safeTransfer(msg.sender, amount);

        emit EmergencyWithdraw(msg.sender, amount);
    }

    function remove(uint256 index)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (address[] memory)
    {
        if (index >= tokenAddresses.length) return tokenAddresses;

        for (uint256 i = index; i < tokenAddresses.length - 1; i++) {
            tokenAddresses[i] = tokenAddresses[i + 1];
        }
        tokenAddresses.pop();
        return tokenAddresses;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function _stake(uint256 _amount) private {
        _totalSupply = _totalSupply.add(_amount);
        _balances[msg.sender] = _balances[msg.sender].add(_amount);
        //stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function _withdraw(uint256 _amount) private {
        _totalSupply = _totalSupply.sub(_amount);
        _balances[msg.sender] = _balances[msg.sender].sub(_amount);
        //stakingToken.safeTransfer(msg.sender, _amount);
    }

    function _notifyRewardAmount(address rewardTokenAddress, uint256 reward)
        internal
    {
        updateReward(address(0));
        RewardToken storage rewardTokenStruct = rewardTokens[
            rewardTokenAddress
        ];
        rewardTokenStruct.rewardRate = reward.mul(1e18).div(
            rewardTokenStruct.duration
        );
        rewardTokenStruct.lastUpdateTime = block.timestamp;
        rewardTokenStruct.periodFinish = block.timestamp.add(
            rewardTokenStruct.duration
        );
        emit RewardAdded(reward);
    }

    function dailyRewardApy(address token) external view returns (uint256) {
        uint256 rate = rewardTokens[token].rewardRate;
        uint256 dailyReward = rate.div(1e18);
        return (dailyReward * 86400);
    }

    /* -----------     LiquidityMining START----------------------- */

    /*  ----------     FARMING Variables    --------------------*/
    struct Staker {
        uint256 amount;
        uint256 lpAmount;
        uint256 lpToSepa;
        uint256 points;
        uint256 timestamp;
        bool isExist;
        bool farm;
        bool lp;
    }

    uint256 public total;
    uint256 immutable fixedConstantPerToken;
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");
    mapping(address => Staker) public stakers;
    IERC20 private _token = IERC20(address(0));

    /* -----------     FARMING EVENTS   ----------------------- */
    event SenderDeposited(
        address indexed _sender,
        uint256 _amount,
        uint256 _timestamp
    );
    event SenderWithdrawed(
        address indexed _sender,
        uint256 _amount,
        uint256 _timestamp
    );
    event GivenPoints(address indexed _address, uint256 _point);
    event PaymentOccured(address indexed _buyer, uint256 _amount);

    /* -----------  FARM FUNCTIONS START ----------------------- */
    constructor(
        IERC20 token,
        uint256 tokenMultiplier,
        address crowdsaleFactory
    ) {
        _token = token;
        fixedConstantPerToken = tokenMultiplier * 1e18;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, crowdsaleFactory);
    }

    function getTokenAddress() external view returns (address) {
        return address(_token);
    }

    function giveAway(address _address, uint256 points)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        stakers[_address].points = points;
        emit GivenPoints(_address, points);
    }

    function farmed(address sender) external view returns (uint256) {
        // Returns how many tokens in this account has farmed
        return (stakers[sender].amount);
    }

    function farmedStart(address sender) external view returns (uint256) {
        // Returns when this account started farming
        return (stakers[sender].timestamp);
    }

    function payment(address buyer, uint256 amount)
        external
        onlyRole(COLLECTION)
        returns (bool)
    {
        consolidate(buyer);
        Staker storage st = stakers[buyer];

        require(st.points > 0, "accrued points equal to 0");
        require(st.points >= amount, "Insufficient points!");

        st.points -= amount;

        emit PaymentOccured(buyer, amount);
        return true;
    }

    function getConsolidatedRewards(address buyer)
        external
        view
        returns (uint256)
    {
        return stakers[buyer].points;
    }

    function rewardedPoints(address staker) public view returns (uint256) {
        Staker storage st = stakers[staker];
        uint256 _seconds = block.timestamp.sub(st.timestamp);
        uint256 earnPerSec = fixedConstantPerToken / (60 * 60 * 24);
        uint256 result = (st.points +
            ((st.amount * earnPerSec) * _seconds) /
            1e18) + _rewardedPointsLp(staker);
        return result;
    }

    function consolidate(address staker) internal {
        uint256 points = rewardedPoints(staker);
        stakers[staker].points = points;
        stakers[staker].timestamp = block.timestamp;
    }

    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Insufficient amount");
        require(
            _token.balanceOf(msg.sender) >= amount,
            "Insufficient amount for deposit"
        );

        _setupRole(WITHDRAW_ROLE, msg.sender);
        address sender = msg.sender;
        // Staker memory stakerData = stakers[sender];
        _token.safeTransferFrom(sender, address(this), amount);
        consolidate(sender);

        total = total + amount;
        stakers[sender].amount += amount;
        stakers[sender].farm = true;

        updateReward(msg.sender);
        _stake(amount);

        // solium-disable-next-line security/no-block-members
        emit SenderDeposited(sender, amount, block.timestamp);
    }

    function withdraw(uint256 amount) public {
        updateReward(msg.sender);
        address sender = msg.sender;

        require(amount > 0, "amount cannot be zero!");
        require(stakers[sender].amount >= amount, "Insufficient amount!");
        require(_token.transfer(address(sender), amount), "Transfer error!");

        consolidate(sender);
        stakers[sender].amount -= amount;
        if (stakers[sender].amount == 0) {
            stakers[sender].farm = false;
        }
        total = total - amount;
        // solium-disable-next-line security/no-block-members
        _withdraw(amount);
        uint256 len = tokenAddresses.length;
        for (uint256 i = 0; i < len; i++) {
            uint256 reward = rewardTokens[tokenAddresses[i]].rewards[
                msg.sender
            ];
            if (reward > 0) {
                getReward(tokenAddresses[i]);
            }
        }

        emit SenderWithdrawed(sender, amount, block.timestamp);
    }

    /*  ----------     LP Variables    --------------------*/

    IUniswapV2Pair uniPair;
    uint256 totalLp;

    /* -----------     LP EVENTS   ----------------------- */
    event LpDeposited(
        address indexed _sender,
        uint256 _lpAmount,
        uint256 _sepaAmount,
        uint256 _timestamp
    );

    event LpWithdrawed(
        address indexed _sender,
        uint256 _lpAmount,
        uint256 _timestamp
    );

    function setUniswapPairAddress(address _sepaWethPair)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uniPair = IUniswapV2Pair(_sepaWethPair);
    }

    function _calcSepaToken(uint256 lpAmount) private view returns (uint256) {
        uint256 userLpRatio = (lpAmount * (1e36)) / uniPair.totalSupply();
        (uint256 sepaReserve, , ) = uniPair.getReserves();
        uint256 sepaAmount = (userLpRatio * sepaReserve) / (1e36);
        return sepaAmount;
    }

    function _rewardedPointsLp(address staker) private view returns (uint256) {
        Staker storage st = stakers[staker];
        uint256 _seconds = block.timestamp.sub(st.timestamp);
        uint256 earnPerSec = fixedConstantPerToken / (60 * 60 * 24);
        return (((st.lpToSepa * earnPerSec) * _seconds) / 1e18) * 2;
    }

    function depositLp(uint256 lpAmount) external nonReentrant {
        require(lpAmount > 0, "Insufficient amount");
        require(
            uniPair.balanceOf(msg.sender) >= lpAmount,
            "Insufficient amount for deposit"
        );

        uint256 sepaAmount = _calcSepaToken(lpAmount);

        require(sepaAmount > 0, "Insufficient amount");

        address sender = msg.sender;

        uniPair.transferFrom(sender, address(this), lpAmount);
        consolidate(sender);

        totalLp += lpAmount;
        stakers[sender].lpToSepa += sepaAmount;
        stakers[sender].lpAmount += lpAmount;
        stakers[sender].lp = true;

        emit LpDeposited(sender, lpAmount, sepaAmount, block.timestamp);
    }

    function withdrawLp(uint256 lpAmount) public {
        address sender = msg.sender;

        require(lpAmount > 0, "amount cannot be zero!");
        require(stakers[sender].lpAmount >= lpAmount, "Insufficient amount!");
        require(uniPair.transfer(address(sender), lpAmount), "Transfer error!");

        consolidate(sender);
        stakers[sender].lpAmount -= lpAmount;

        if (stakers[sender].lpAmount == 0) {
            stakers[sender].lp = false;
            stakers[sender].lpToSepa = 0;
        } else {
            stakers[sender].lpToSepa = _calcSepaToken(stakers[sender].lpAmount);
        }

        totalLp = totalLp - lpAmount;

        emit LpWithdrawed(sender, lpAmount, block.timestamp);
    }
}
