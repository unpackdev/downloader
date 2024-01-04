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

contract GlobalPool_R27 is Lockable, Pausable {

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

    mapping(address => uint256) private _pendingUserStakes;
    mapping(address => uint256) private _userStakes;

    mapping(address => uint256) private _rewards;
    mapping(address => uint256) private _claims;

    mapping(address => uint256) private _etherBalances;
    mapping(address => uint256) private _slashings;

    mapping(address => uint256) private _exits;

    // Pending staker list
    address[] private _pendingStakers;
    // total pending amount
    uint256 private _pendingAmount;
    // total stakes of all users
    uint256 private _totalStakes;
    // total rewards for all stakers
    uint256 private _totalRewards;

    IAETH private _aethContract;

    IStaking private _stakingContract;

    SystemParameters private _systemParameters;

    address _depositContract;

    address[] private _pendingTemp;

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

    function multipleDeposit(bytes[] calldata pubkey,
        bytes[] calldata withdrawal_credentials,
        bytes[] calldata signature,
        bytes32[] calldata deposit_data_root) public onlyOperator {
        uint256 pubkeyLength = pubkey.length;
        require(
            pubkeyLength == withdrawal_credentials.length &&
            pubkeyLength == signature.length &&
            pubkeyLength == deposit_data_root.length, "Multiple Deposit: Array lengths must be equal");

        for(uint32 i = 0; i < pubkeyLength; i++) {
            _deposit(pubkey[i], withdrawal_credentials[i], signature[i], deposit_data_root[i]);
        }
    }

    function pushToBeacon(bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root) public onlyOperator {
        _deposit(pubkey, withdrawal_credentials, signature, deposit_data_root);
    }

    function _deposit(bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root) private {

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

        for(uint256 i = 0; i < amounts.length; i++) {
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
        _totalStakes = _totalStakes.add(msg.value);

        uint256 _ratio = _aethContract.ratio();
        if (payRewards) {
            _aETHRewards[staker] = _aETHRewards[staker].add(value.mul(_ratio).div(1e18));
            _fETHRewards[staker][0] = _fETHRewards[staker][0].add(value);
            _fETHRewards[staker][1] = _fETHRewards[staker][1].add(value.mul(_fethMintBase).div(32 ether));
        }
        emit StakePending(staker, value);
        emit StakeConfirmed(staker, value);
    }

    function topUpETH() public whenNotPaused("topUpETH") notExitRecently(msg.sender) payable {
        require(_configContract.getConfig("PROVIDER_MINIMUM_ETH_STAKING") <= msg.value, "Value must be greater than minimum amount");
        _etherBalances[msg.sender] = _etherBalances[msg.sender].add(msg.value);
        //           _etherBalances[msg.sender] = _etherBalances[msg.sender].add(msg.value);

        _stake(msg.sender, msg.value, false);

        emit ProviderToppedUpEth(msg.sender, msg.value);
    }

    function topUpANKR(uint256 amount) public whenNotPaused("topUpANKR") notExitRecently(msg.sender) {
        require(_configContract.getConfig("PROVIDER_MINIMUM_ANKR_STAKING") <= amount, "Value must be greater than minimum amount");
        require(_stakingContract.freeze(msg.sender, amount), "Not enough allowance or balance");

        emit ProviderToppedUpAnkr(msg.sender, amount);
    }

    // slash provider with ethereum balance
    function slash(address provider, uint256 amount) public unlocked(provider) onlyOwner {
        require(amount > 0, "Amount should be greater than zero");
        _slashETH(provider, amount);
    }

    function providerExit() public {
        int256 available = availableEtherBalanceOf(msg.sender);
        address staker = msg.sender;
        require(available > 0, "Provider balance should be positive for exit");
        _exits[staker] = block.number;

        _etherBalances[staker] = 0;
        _slashings[staker] = 0;

        _aETHRewards[staker] = _aETHRewards[staker].add(uint256(available));

        emit ProviderExited(msg.sender);
    }

    function claim() public whenNotPaused("claim") notExitRecently(msg.sender) {
        claimAETH();
    }

    function claimableRewardOf(address staker) public view returns (uint256) {
        // for backwards compatibility
        return claimableAETHRewardOf(staker);
    }

    function claimableAETHRewardOf(address staker) public view returns (uint256) {
        uint256 blocked = _etherBalances[staker];
        uint256 reward = _rewards[staker].sub(_claims[staker]);
        reward = blocked >= reward ? 0 : reward.sub(blocked);

        return _aETHRewards[staker].sub(reward);
    }

    function claimableAETHFRewardOf(address staker) public view returns (uint256) {
        uint256 blocked = _etherBalances[staker];
        uint256 reward = _fETHRewards[staker][0];

        return reward;
    }

    function claimAETH() whenNotPaused("claim") public {
        address staker = msg.sender;
        uint256 claimable = claimableAETHRewardOf(staker);
        require(claimable > 0, "claimable reward zero");

        _fETHRewards[staker][0] = 0;
        _fETHRewards[staker][1] = 0;
        _aETHRewards[staker] = 0;
        uint256 oldReward = _rewards[staker].sub(_claims[staker]);
        if (oldReward > 0) {
            _claims[staker] = _claims[staker].add(oldReward);
        }

        _aethContract.mint(staker, claimable);
        emit RewardClaimed(staker, claimable, true);
    }

    function claimFETH() whenNotPaused("claim") public {
        address staker = msg.sender;
        uint256 claimable = claimableAETHFRewardOf(staker);
        uint256 shares = _fETHRewards[staker][1];
        require(claimable > 0, "claimable reward zero");

        _fETHRewards[staker][0] = 0;
        _fETHRewards[staker][1] = 0;
        _aETHRewards[staker] = 0;

        _fethContract.mint(staker, shares, claimable);
        emit RewardClaimed(staker, claimable, false);
    }

    function unstake() public whenNotPaused("unstake") payable unlocked(msg.sender) notExitRecently(msg.sender) {
        uint256 pendingStakes = pendingStakesOf(msg.sender);

        require(pendingStakes > 0, "No pending stakes");

        _pendingUserStakes[msg.sender] = 0;
        _pendingEtherBalances[msg.sender] = 0;

        require(msg.sender.send(pendingStakes), "could not send ethers");

        emit StakeRemoved(msg.sender, pendingStakes);
    }

    function availableEtherBalanceOf(address provider) public view returns (int256) {
        return int256(etherBalanceOf(provider) - slashingsOf(provider));
    }

    function etherBalanceOf(address provider) public view returns (uint256) {
        return _etherBalances[provider];
    }

    function updateEther(address provider, uint256 val) public onlyOperator {
        _etherBalances[provider] = val;
    }

    function pendingEtherBalanceOf(address provider) public view returns (uint256) {
        return _pendingEtherBalances[provider];
    }

    function slashingsOf(address provider) public view returns (uint256) {
        return _slashings[provider];
    }

    /**
        @dev Slash eth, returns remaining needs to be slashed
    */
    function _slashETH(address provider, uint256 amount) private returns (uint256 remaining) {

        uint256 available = availableEtherBalanceOf(provider) > 0 ? uint256(availableEtherBalanceOf(provider)) : 0;

        uint256 toBeSlashed = amount.min(available);
        if (toBeSlashed == 0) return amount;

        _slashings[provider] = _slashings[provider].add(toBeSlashed);
        remaining = amount.sub(toBeSlashed);

        emit ProviderSlashedEth(provider, toBeSlashed);
    }

    function poolCount() public view returns (uint256) {
        return _totalStakes.div(32 ether);
    }

    function pendingStakesOf(address staker) public view returns (uint256) {
        return _pendingUserStakes[staker];
    }

    function updateAETHContract(address payable tokenContract) external onlyOwner {
        _aethContract = IAETH(tokenContract);
    }

    function updateFETHContract(address payable tokenContract) external onlyOwner {
        _fethContract = IFETH(tokenContract);
    }

    function updateConfigContract(address configContract) external onlyOwner {
        _configContract = IConfig(configContract);
    }

    function updateStakingContract(address stakingContract) external onlyOwner {
        _stakingContract = IStaking(stakingContract);
    }

    function clearEmptyPendingStakers() public onlyOwner {
        // we should remove stakers from pending array length is: i
        for (uint256 j = 0; j < _pendingStakers.length; j++) {
            address staker = _pendingStakers[j];
            if (_pendingUserStakes[staker] > 0) {
                _pendingTemp.push(staker);
            }
        }

        _pendingStakers = _pendingTemp;

        delete _pendingTemp;
        _lastPendingStakerPointer = 0;
    }

    function deleteLastPendingStakerPointer() public onlyOwner {
        _lastPendingStakerPointer = 0;
    }

    function changeOperator(address operator) public onlyOwner {
        _operator = operator;
    }

    function depositContractAddress() public view returns (address) {
        return _depositContract;
    }

    function updateFETHRewards(uint256 _totalRewards) public onlyOperator {
        if (_totalRewards == 0) {
            _fethMintBase = 1 ether;
            return;
        }

        uint256 totalSent = _fethContract.updateReward(_totalRewards);
        _fethMintBase = totalSent.mul(1 ether).div(_totalRewards.add(totalSent));
    }

    function updateRewards(address[] memory user, uint256[] memory claims, uint256[] memory rewards) public onlyOwner {
        require(user.length == claims.length && claims.length == rewards.length, "Lengths not equal");
        for(uint256 i = 0; i < user.length; i++) {
            address user = user[i];
            _claims[user] = claims[i];
            _rewards[user] = rewards[i];
        }
    }

    function syncPendingStakers() public {
        address[] memory pending = _pendingStakers;
        uint256 lng = pending.length;
        uint256 _ratio = _aethContract.ratio();
        for(uint256 i = 0; i < lng; i++) {
            address staker = pending[i];
            uint256 value = _pendingUserStakes[staker];
            if (_pendingUserStakes[staker] > 0) {
                _aETHRewards[staker] = _aETHRewards[staker].add(value.mul(_ratio).div(1e18));
                _fETHRewards[staker][0] = _fETHRewards[staker][0].add(value);
                _fETHRewards[staker][1] = _fETHRewards[staker][1].add(value.mul(_fethMintBase).div(32 ether));

                emit StakeConfirmed(staker, value);

                _pendingUserStakes[staker] = 0;

            }

            if (_pendingEtherBalances[staker] > 0) {
                _etherBalances[staker] = _etherBalances[staker].add(_pendingEtherBalances[staker]);
                _pendingEtherBalances[staker] = 0;
            }
        }
    }

    uint256[50] private __gap;

    uint256 private _lastPendingStakerPointer;

    IConfig private _configContract;

    mapping(address => uint256) private _pendingEtherBalances;

    address private _operator;

    mapping (address => uint256[2]) private _fETHRewards;
    mapping (address => uint256) private _aETHRewards;

    IFETH private _fethContract;

    uint256 private _fethMintBase;
}
