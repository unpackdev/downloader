// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.11;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Math.sol";
import "./IERC20.sol";
import "./IDepositContract.sol";
import "./SystemParameters.sol";
import "./Lockable.sol";
import "./IAETH.sol";
import "./IFETH.sol";
import "./IConfig.sol";
import "./IStaking.sol";
import "./IDepositContract.sol";
import "./Pausable.sol";

contract GlobalPool_R31 is Lockable, Pausable {

    using SafeMath for uint256;
    using Math for uint256;

    /* staker events */
    event StakePending(address indexed staker, uint256 amount);
    event StakeConfirmed(address indexed staker, uint256 amount);
    event StakeRemoved(address indexed staker, uint256 amount);

    /* pool events */
    event PoolOnGoing(bytes pool);
    event PoolCompleted(bytes pool);

    /* provider events */
    event ProviderSlashedAnkr(address indexed provider, uint256 ankrAmount, uint256 etherEquivalence);
    event ProviderSlashedEth(address indexed provider, uint256 amount);
    event ProviderToppedUpEth(address indexed provider, uint256 amount);
    event ProviderToppedUpAnkr(address indexed provider, uint256 amount);
    event ProviderExited(address indexed provider);

    /* rewards (AETH) */
    event RewardClaimed(address indexed staker, uint256 amount, bool isAETH);

    // deleted fields
    mapping(address => uint256) private _pendingUserStakes; // deleted

    mapping(address => uint256) private _userStakes;
    mapping(address => uint256) private _rewards;
    mapping(address => uint256) private _claims;
    mapping(address => uint256) private _etherBalances;
    mapping(address => uint256) private _slashings;
    mapping(address => uint256) private _exits;

    // deleted fields
    address[] private _pendingStakers; // deleted
    uint256 private _pendingAmount; // deleted
    uint256 private _totalStakes; // deleted
    uint256 private _totalRewards; // deleted

    IAETH private _aethContract;
    IStaking private _stakingContract;
    SystemParameters private _systemParameters;
    address private _depositContract;

    // deleted fields
    address[] private _pendingTemp; // deleted
    uint256[50] private __gap; // deleted
    uint256 private _lastPendingStakerPointer; // deleted

    IConfig private _configContract;

    // deleted fields
    mapping(address => uint256) private _pendingEtherBalances; // deleted

    address private _operator;

    // deleted fields
    mapping(address => uint256[2]) private _fETHRewards; // deleted

    mapping(address => uint256) private _aETHRewards;
    IFETH private _fethContract;

    // deleted fields
    uint256 private _fethMintBase; // deleted

    modifier notExitRecently(address provider) {
        require(block.number > _exits[provider].add(_configContract.getConfig("EXIT_BLOCKS")), "Recently exited");
        delete _exits[msg.sender];
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == owner() || msg.sender == _operator, "Operator: not allowed");
        _;
    }

    function initialize(IAETH aethContract, SystemParameters parameters, address depositContract) public initializer {
        __Ownable_init();

        _depositContract = depositContract;
        _aethContract = aethContract;
        _systemParameters = parameters;

        _paused["topUpETH"] = true;
        _paused["topUpANKR"] = true;
    }

    function pushToBeacon(bytes calldata pubkey, bytes calldata withdrawal_credentials, bytes calldata signature, bytes32 deposit_data_root) public onlyOperator {
        require(address(this).balance >= 32 ether, "pending ethers not enough");
        IDepositContract(_depositContract).deposit{value : 32 ether}(pubkey, withdrawal_credentials, signature, deposit_data_root);
        emit PoolOnGoing(pubkey);
    }

    function stake() public whenNotPaused("stake") notExitRecently(msg.sender) unlocked(msg.sender) payable {
        _stake(msg.sender, msg.value, true);
    }

    function customStake(address[] memory addresses, uint256[] memory amounts) public payable onlyOperator {
        require(addresses.length == amounts.length, "Addresses and amounts length must be equal");
        uint256 totalSent = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalSent += amounts[i];
            _stake(addresses[i], amounts[i], false);
        }
        require(msg.value == totalSent, "Total value must be same with sent");
    }

    function _stake(address staker, uint256 value, bool payRewards) private {
        uint256 minimumStaking = _configContract.getConfig("REQUESTER_MINIMUM_POOL_STAKING");
        require(value >= minimumStaking, "Value must be greater than zero");
        require(value % minimumStaking == 0, "Value must be multiple of minimum staking amount");
        _userStakes[staker] = _userStakes[staker].add(value);
        uint256 _ratio = _aethContract.ratio();
        if (payRewards) {
            uint256 shares = value.mul(_ratio).div(1e18);
            _aethContract.mint(address(this), shares);
            _aETHRewards[staker] = _aETHRewards[staker].add(shares);
        }
        emit StakePending(staker, value);
        emit StakeConfirmed(staker, value);
    }

    function topUpETH() public whenNotPaused("topUpETH") notExitRecently(msg.sender) payable {
        require(_configContract.getConfig("PROVIDER_MINIMUM_ETH_STAKING") <= msg.value, "Value must be greater than minimum amount");
        _etherBalances[msg.sender] = _etherBalances[msg.sender].add(msg.value);
        _stake(msg.sender, msg.value, true);
        emit ProviderToppedUpEth(msg.sender, msg.value);
    }

    function topUpANKR(uint256 amount) public whenNotPaused("topUpANKR") notExitRecently(msg.sender) {
        require(_configContract.getConfig("PROVIDER_MINIMUM_ANKR_STAKING") <= amount, "Value must be greater than minimum amount");
        require(_stakingContract.freeze(msg.sender, amount), "Not enough allowance or balance");
        emit ProviderToppedUpAnkr(msg.sender, amount);
    }

    function providerExit() public {
        int256 available = availableEtherBalanceOf(msg.sender);
        address staker = msg.sender;
        require(available > 0, "Provider balance should be positive for exit");
        _exits[staker] = block.number;
        _etherBalances[staker] = 0;
        _slashings[staker] = 0;
        uint256 value = uint256(available);
        uint256 _ratio = _aethContract.ratio();
        _aETHRewards[staker] = _aETHRewards[staker].add(value.mul(_ratio).div(1e18));
        emit ProviderExited(msg.sender);
    }

    function claimableAETHRewardOf(address staker) public view returns (uint256) {
        uint256 blocked = _etherBalances[staker];
        uint256 reward = _rewards[staker].sub(_claims[staker]);
        reward = blocked >= reward ? 0 : reward.sub(blocked);
        return _aETHRewards[staker].add(reward);
    }

    function claimableFETHRewardOf(address staker) public view returns (uint256) {
        return claimableAETHRewardOf(staker).mul(1e18).div(_aethContract.ratio());
    }

    function claimableAETHFRewardOf(address staker) public view returns (uint256) {
        return claimableFETHRewardOf(staker);
    }

    function claimAETH() whenNotPaused("claim") public {
        address staker = msg.sender;
        uint256 claimableShares = claimableAETHRewardOf(staker);
        require(claimableShares > 0, "claimable reward zero");
        _aETHRewards[staker] = 0;
        uint256 oldReward = _rewards[staker].sub(_claims[staker]);
        if (oldReward > 0) {
            _claims[staker] = _claims[staker].add(oldReward);
        }
        _aethContract.mint(staker, claimableShares);
        emit RewardClaimed(staker, claimableShares, true);
    }

    function claimFETH() whenNotPaused("claim") public {
        address staker = msg.sender;
        uint256 claimableShares = claimableAETHRewardOf(staker);
        require(claimableShares > 0, "claimable reward zero");
        _aETHRewards[staker] = 0;
        uint256 oldReward = _rewards[staker].sub(_claims[staker]);
        if (oldReward > 0) {
            _claims[staker] = _claims[staker].add(oldReward);
        }
        _aethContract.mintApprovedTo(staker, address(_fethContract), claimableShares);
        _fethContract.lockShares(staker, claimableShares);
        emit RewardClaimed(staker, claimableShares, false);
    }

    function availableEtherBalanceOf(address provider) public view returns (int256) {
        return int256(etherBalanceOf(provider)) - int256(slashingsOf(provider));
    }

    function etherBalanceOf(address provider) public view returns (uint256) {
        return _etherBalances[provider];
    }

    function slashingsOf(address provider) public view returns (uint256) {
        return _slashings[provider];
    }

    /**
        @dev Slash eth, returns remaining needs to be slashed
    */
    function slashETH(address provider, uint256 amount) public unlocked(provider) onlyOwner returns (uint256 remaining) {
        require(amount > 0, "Amount should be greater than zero");
        uint256 available = availableEtherBalanceOf(provider) > 0 ? uint256(availableEtherBalanceOf(provider)) : 0;
        uint256 toBeSlashed = amount.min(available);
        if (toBeSlashed == 0) return amount;
        _slashings[provider] = _slashings[provider].add(toBeSlashed);
        remaining = amount.sub(toBeSlashed);
        emit ProviderSlashedEth(provider, toBeSlashed);
    }

    function updateAETHContract(address payable aEthContract) external onlyOwner {
        _aethContract = IAETH(aEthContract);
    }

    function updateFETHContract(address payable fEthContract) external onlyOwner {
        _fethContract = IFETH(fEthContract);
    }

    function updateConfigContract(address configContract) external onlyOwner {
        _configContract = IConfig(configContract);
    }

    function updateStakingContract(address stakingContract) external onlyOwner {
        _stakingContract = IStaking(stakingContract);
    }

    function changeOperator(address operator) public onlyOwner {
        _operator = operator;
    }

    function depositContractAddress() public view returns (address) {
        return _depositContract;
    }
}
