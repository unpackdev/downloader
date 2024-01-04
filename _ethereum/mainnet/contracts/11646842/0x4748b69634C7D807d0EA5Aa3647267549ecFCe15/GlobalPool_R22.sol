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
import "./IConfig.sol";
import "./IStaking.sol";
import "./IDepositContract.sol";
import "./Pausable.sol";

contract GlobalPool_R22 is Lockable, Pausable {

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
    event RewardClaimed(address indexed staker, uint256 amount);

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

        require(_pendingAmount >= 32 ether, "pending ethers not enough");
        // substract 32 ether from pending amount
        _pendingAmount = _pendingAmount.sub(32 ether);

        uint256 _amount = 0;
        uint256 _pendingProviderBalance = 0;

        uint256 _ratio = _aethContract.ratio();

        uint256 i = _lastPendingStakerPointer > 0 ? _lastPendingStakerPointer.sub(1) : 0;

        while (_amount < 32 ether) {
            address staker = _pendingStakers[i];
            i++;
            uint256 userStake = _pendingUserStakes[staker];
            // if user dont have any stake...
            if (userStake == 0) continue;

            uint256 providerStake = _pendingEtherBalances[staker];

            _amount = _amount.add(userStake);

            // if amount bigger then 32 ethereum, give back remaining user amount to pending
            if (_amount > 32 ether) {
                i--;
                uint256 remained = _amount.sub(32 ether);
                uint256 sent = userStake.sub(remained);
                // set pending user stakes to zero
                _pendingUserStakes[staker] = remained;

                if (providerStake > 0) {
                    // get new pending ether
                    uint256 newPendingEther = providerStake > sent ? providerStake.sub(sent) : 0;
                    uint256 userProviderStake = _pendingEtherBalances[staker].sub(newPendingEther);

                    // calculate ether balance for user
                    // which is old balance plus, old pending ether minus new pending ether
                    _etherBalances[staker] = _etherBalances[staker].add(userProviderStake);

                    // add provider stake to pending provider balance
                    _pendingProviderBalance = _pendingProviderBalance.add(userProviderStake);

                    // set new pending ether balance
                    _pendingEtherBalances[staker] = newPendingEther;
                }

                // add reward for staker
                _rewards[staker] = _rewards[staker].add(sent.mul(_ratio).div(1e18));

                emit StakeConfirmed(staker, sent);
                break;
            }
            // set pending user stakes to zero
            _pendingUserStakes[staker] = 0;
            _etherBalances[staker] = _etherBalances[staker].add(_pendingEtherBalances[staker]);

            // add provider stake to pending provider balance
            _pendingProviderBalance = _pendingProviderBalance.add(providerStake);

            _pendingEtherBalances[staker] = 0;
            // add reward for staker
            _rewards[staker] = _rewards[staker].add(userStake.mul(_ratio).div(1e18));
            emit StakeConfirmed(staker, userStake);
        }

        _lastPendingStakerPointer = i;

        // mint aETH
        _aethContract.mint(address(this), uint256(32 ether).sub(_pendingProviderBalance).mul(_ratio).div(1e18));

        // send funds to deposit contract
        IDepositContract(_depositContract).deposit{value : 32 ether}(pubkey, withdrawal_credentials, signature, deposit_data_root);

        emit PoolOnGoing(pubkey);
    }

    function stake() public whenNotPaused("stake") notExitRecently(msg.sender) unlocked(msg.sender) payable {
        _stake(msg.sender, msg.value);
    }

    function _stake(address staker, uint256 value) private {
        uint256 minimumStaking = _configContract.getConfig("REQUESTER_MINIMUM_POOL_STAKING");

        require(value >= minimumStaking, "Value must be greater than zero");
        require(value % minimumStaking == 0, "Value must be multiple of minimum staking amount");

        if (_pendingUserStakes[staker] == 0) {
            _pendingStakers.push(staker);
        }

        _pendingUserStakes[staker] = _pendingUserStakes[staker].add(value);
        _pendingAmount = _pendingAmount.add(value);

        _userStakes[staker] = _userStakes[staker].add(value);

        _totalStakes = _totalStakes.add(msg.value);

        emit StakePending(staker, value);
    }

    function topUpETH() public whenNotPaused("topUpETH") notExitRecently(msg.sender) payable {
        require(_configContract.getConfig("PROVIDER_MINIMUM_ETH_STAKING") <= msg.value, "Value must be greater than minimum amount");
        _pendingEtherBalances[msg.sender] = _pendingEtherBalances[msg.sender].add(msg.value);
        //           _etherBalances[msg.sender] = _etherBalances[msg.sender].add(msg.value);

        _stake(msg.sender, msg.value);

        emit ProviderToppedUpEth(msg.sender, msg.value);
    }

    function topUpANKR(uint256 amount) public whenNotPaused("topUpANKR") notExitRecently(msg.sender) payable {
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
        require(available > 0, "Provider balance should be positive for exit");
        _exits[msg.sender] = block.number;

        _etherBalances[msg.sender] = 0;
        _slashings[msg.sender] = 0;

        _aethContract.mint(msg.sender, uint256(available));

        emit ProviderExited(msg.sender);
    }

    function claim() public whenNotPaused("claim") notExitRecently(msg.sender) {
        _claim(msg.sender);
    }

    function claimFor(address staker) public whenNotPaused("claim") notExitRecently(staker) {
        _claim(staker);
    }

    function claimableRewardOf(address staker) public view returns (uint256) {
        uint256 blocked = _etherBalances[staker];
        uint256 reward = _rewards[staker].sub(_claims[staker]);

        return blocked >= reward ? 0 : reward.sub(blocked);
    }

    function _claim(address staker) private {
        uint256 claimable = claimableRewardOf(staker);
        require(claimable > 0, "claimable reward zero");

        _claims[staker] = _claims[staker].add(claimable);

        _aethContract.transfer(staker, claimable);

        emit RewardClaimed(staker, claimable);
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

    uint256[50] private __gap;

    uint256 private _lastPendingStakerPointer;

    IConfig private _configContract;

    mapping(address => uint256) private _pendingEtherBalances;

    address private _operator;
}