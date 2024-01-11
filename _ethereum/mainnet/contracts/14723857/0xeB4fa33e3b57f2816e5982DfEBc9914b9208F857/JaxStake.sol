// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./Initializable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IPancakeRouter.sol";
import "./JaxProtection.sol";

interface IJaxStakeAdmin {

    function owner() external view returns(address);

    function wjxn() external view returns(IERC20MetadataUpgradeable);
    function usdt() external view returns(IERC20MetadataUpgradeable);

    function apys(uint plan) external view returns (uint);
    
    function min_unlocked_deposit_amount() external view returns (uint);
    function max_unlocked_deposit_amount() external view returns (uint);

    function min_locked_deposit_amount() external view returns (uint);
    function max_locked_deposit_amount() external view returns (uint);

    function collateral_ratio() external view returns (uint);

    function referral_ratio() external view returns (uint);

    function wjxn_default_discount_ratio() external view returns (uint);

    function lock_plans(uint plan) external view returns(uint);

    function max_unlocked_stake_amount() external view returns (uint);

    function max_locked_stake_amount() external view returns (uint);

    function get_wjxn_price() external view returns(uint);
    function is_deposit_freezed() external view returns(bool);
    function referrers(uint id) external view returns(address);
    function referrer_status(uint id) external view returns(bool);
}

contract JaxStake is Initializable, JaxProtection, ReentrancyGuardUpgradeable {
    
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    IJaxStakeAdmin public stakeAdmin;

    uint public total_stake_amount;
    uint public unlocked_stake_amount;
    uint public locked_stake_amount;


    struct Stake {
        uint amount;
        uint apy;
        uint reward_released;
        uint start_timestamp;
        uint harvest_timestamp;
        uint end_timestamp;
        uint unstake_timestamp;
        uint referral_id;
        address owner;
        uint plan;
        bool is_withdrawn;
    }

    Stake[] public stake_list;
    mapping(address => uint[]) public user_stakes; 
    mapping(address => bool) public is_user_unlocked_staking;

    struct Accountant {
        address account;
        address withdrawal_address;
        address withdrawal_token;
        uint withdrawal_limit;
    }

    Accountant[] public accountants;
    mapping(address => uint) public accountant_to_ids;

    event Stake_USDT(uint stake_id, uint plan, uint amount, uint referral_id);
    event Harvest(uint stake_id, uint amount);
    event Unstake(uint stake_id);
    event Add_Accountant(uint id, address account, address withdrawal_address, address withdrawal_token, uint withdrawal_limit);
    event Set_Accountant_Withdrawal_Limit(uint id, uint limit);
    event Withdraw_By_Accountant(uint id, address token, address withdrawal_address, uint amount);
    event Withdraw_By_Admin(address token, uint amount);

    modifier checkZeroAddress(address account) {
        require(account != address(0x0), "Only non-zero address");
        _;
    }

    modifier onlyOwner() {
      require(stakeAdmin.owner() == msg.sender, "Caller is not the owner");
      _;
    }

    function initialize(IJaxStakeAdmin _stakeAdmin) external initializer checkZeroAddress(address(_stakeAdmin)) {
        __ReentrancyGuard_init();
        stakeAdmin = _stakeAdmin;
        Accountant memory accountant;
        accountants.push(accountant);
    }

    function stake_usdt(uint plan, uint amount, uint referral_id) external nonReentrant {
        _stake_usdt(plan, amount, referral_id, false);    
    }

    function _stake_usdt(uint plan, uint amount, uint referral_id, bool is_restake) internal {
        require(plan <= 4, "Invalid plan");
        require(!stakeAdmin.is_deposit_freezed(), "Staking is freezed");
        IERC20MetadataUpgradeable usdt = stakeAdmin.usdt();
        if(!is_restake)
            usdt.safeTransferFrom(msg.sender, address(this), amount);
        uint collateral = stakeAdmin.wjxn().balanceOf(address(this));
        total_stake_amount += amount;
        _check_collateral(collateral, total_stake_amount);
        Stake memory stake;
        stake.amount = amount;
        stake.plan = plan;
        stake.apy = stakeAdmin.apys(plan);
        stake.owner = msg.sender;
        stake.start_timestamp = block.timestamp;
        stake.end_timestamp = block.timestamp + stakeAdmin.lock_plans(plan);
        if(plan == 0){ // Unlocked staking
            require(amount >= stakeAdmin.min_unlocked_deposit_amount() && amount <= stakeAdmin.max_unlocked_deposit_amount(), "Out of limit");
            unlocked_stake_amount += amount;
            require(unlocked_stake_amount <= stakeAdmin.max_unlocked_stake_amount(), "max unlocked stake amount");
            require(!is_user_unlocked_staking[msg.sender], "Only one unlocked staking");
            is_user_unlocked_staking[msg.sender] = true;
        }
        else { // Locked Staking
            require(amount >= stakeAdmin.min_locked_deposit_amount() && amount <= stakeAdmin.max_locked_deposit_amount(), "Out of limit");
            locked_stake_amount += amount;
            require(locked_stake_amount <= stakeAdmin.max_locked_stake_amount(), "max locked stake amount");
            if(stakeAdmin.referrer_status(referral_id)) {
                stake.referral_id = referral_id;
                uint referral_amount = amount * stakeAdmin.referral_ratio() * plan / 1e8;
                address referrer = stakeAdmin.referrers(referral_id);
                if(usdt.balanceOf(address(this)) >= referral_amount) {
                    usdt.safeTransfer(referrer, referral_amount);
                }
                else {
                    stakeAdmin.wjxn().safeTransfer(msg.sender, usdt_to_discounted_wjxn_amount(referral_amount));
                }
            }
        }
        stake.harvest_timestamp = stake.start_timestamp;
        uint stake_id = stake_list.length;
        stake_list.push(stake);
        user_stakes[msg.sender].push(stake_id);
        emit Stake_USDT(stake_id, plan, amount, referral_id);
    }
    
    function get_pending_reward(uint stake_id) public view returns(uint) {
        Stake memory stake = stake_list[stake_id];
        uint past_period = 0;
        if(stake.is_withdrawn) return 0;
        if(stake.harvest_timestamp >= stake.end_timestamp) 
            return 0;
        if(block.timestamp >= stake.end_timestamp)
            past_period = stake.end_timestamp - stake.start_timestamp;
        else
            past_period = block.timestamp - stake.start_timestamp;
        uint reward = stake.amount * stake.apy * past_period / 100 / 365 days;
        return reward - stake.reward_released;
    }

    function harvest(uint stake_id) external nonReentrant {
        require(_harvest(stake_id) > 0, "No pending reward");
    }

    function _harvest(uint stake_id) internal returns(uint pending_reward) {
        Stake storage stake = stake_list[stake_id];
        require(stake.owner == msg.sender, "Only staker");
        require(!stake.is_withdrawn, "Already withdrawn");
        pending_reward = get_pending_reward(stake_id);
        if(pending_reward == 0) 
            return 0;
        if(stakeAdmin.usdt().balanceOf(address(this)) >= pending_reward)
            stakeAdmin.usdt().safeTransfer(msg.sender, pending_reward);
        else {
            stakeAdmin.wjxn().safeTransfer(msg.sender, usdt_to_discounted_wjxn_amount(pending_reward));
        }
        stake.reward_released += pending_reward;
        stake.harvest_timestamp = block.timestamp;
        emit Harvest(stake_id, pending_reward);
    }

    function unstake(uint stake_id) external nonReentrant {
        _unstake(stake_id, false);
    }

    function _unstake(uint stake_id, bool is_restake) internal {
        require(stake_id < stake_list.length, "Invalid stake id");
        Stake storage stake = stake_list[stake_id];
        require(stake.owner == msg.sender, "Only staker");
        require(!stake.is_withdrawn, "Already withdrawn");
        require(stake.plan == 0 || stake.end_timestamp <= block.timestamp, "Locked");
        _harvest(stake_id);
        if(!is_restake) {
            if(stake.amount <= stakeAdmin.usdt().balanceOf(address(this)))
                stakeAdmin.usdt().safeTransfer(stake.owner, stake.amount);
            else 
                stakeAdmin.wjxn().safeTransfer(msg.sender, usdt_to_discounted_wjxn_amount(stake.amount));
        }
        if(stake.plan == 0) {
            unlocked_stake_amount -= stake.amount;
            is_user_unlocked_staking[msg.sender] = false;
        }
        else
            locked_stake_amount -= stake.amount;
        stake.is_withdrawn = true;
        stake.unstake_timestamp = block.timestamp;
        total_stake_amount -= stake.amount;
        emit Unstake(stake_id);
    }

    function restake(uint stake_id) external nonReentrant {
        Stake memory stake = stake_list[stake_id];
        _unstake(stake_id, true);
        _stake_usdt(stake.plan, stake.amount, stake.referral_id, true);
    }

    function usdt_to_discounted_wjxn_amount(uint usdt_amount) public view returns (uint){
        return usdt_amount * (10 ** (18 - stakeAdmin.usdt().decimals())) * 100 / (100 - stakeAdmin.wjxn_default_discount_ratio()) / stakeAdmin.get_wjxn_price();
    }

    function _check_collateral(uint collateral, uint stake_amount) internal view {
        uint collateral_in_usdt = collateral * stakeAdmin.get_wjxn_price() * (10 ** stakeAdmin.usdt().decimals()) * 100 / (stakeAdmin.collateral_ratio() * 1e18);  
        require(stake_amount <= collateral_in_usdt, "Lack of collateral");
    }

    function get_user_stakes(address user) external view returns(uint[] memory) {
        return user_stakes[user];
    }

    function add_accountant(address account, address withdrawal_address, address withdrawal_token, uint withdrawal_limit) external onlyOwner runProtection {
        require(accountant_to_ids[account] == 0, "Already exists");
        Accountant memory accountant;
        accountant.account = account;
        accountant.withdrawal_address = withdrawal_address;
        accountant.withdrawal_token = withdrawal_token;
        accountant.withdrawal_limit = withdrawal_limit;
        accountants.push(accountant);
        uint accountant_id = accountants.length - 1;
        accountant_to_ids[account] = accountant_id;
        emit Add_Accountant(accountant_id, account, withdrawal_address, withdrawal_token, withdrawal_limit);
    }

    function set_accountant_withdrawal_limit(uint id, uint limit) external onlyOwner {
        require(id > 0 && id < accountants.length, "Invalid accountant id");
        Accountant storage accountant = accountants[id];
        accountant.withdrawal_limit = limit;
        emit Set_Accountant_Withdrawal_Limit(id, limit);
    }

    function withdraw_by_accountant(uint amount) external nonReentrant runProtection {
        uint id = accountant_to_ids[msg.sender];
        require(id > 0, "Not an accountant");
        Accountant storage accountant = accountants[id];
        require(accountant.withdrawal_limit >= amount, "Out of withdrawal limit");
        IERC20MetadataUpgradeable(accountant.withdrawal_token).safeTransfer(accountant.withdrawal_address, amount);
        accountant.withdrawal_limit -= amount;
        emit Withdraw_By_Accountant(id, accountant.withdrawal_token, accountant.withdrawal_address, amount);
    }

    function withdrawByAdmin(address token, uint amount) external onlyOwner nonReentrant runProtection{
        if(token == address(stakeAdmin.wjxn())) {
            uint collateral = stakeAdmin.wjxn().balanceOf(address(this));
            require(collateral >= amount, "Out of balance");
            _check_collateral(collateral - amount, total_stake_amount);
        }
        IERC20MetadataUpgradeable(token).safeTransfer(msg.sender, amount);
        emit Withdraw_By_Admin(token, amount);
    }  

}