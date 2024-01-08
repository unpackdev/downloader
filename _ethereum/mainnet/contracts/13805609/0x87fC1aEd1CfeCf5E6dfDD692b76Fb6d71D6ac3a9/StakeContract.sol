//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./console.sol";
import "./Initializable.sol";
import "./IERC20.sol";
// import "./SafeERC20.sol";

contract StakeContract is Initializable {

    mapping(bytes32 => uint256) public user_time_created;
    mapping(bytes32 => uint256) public user_coin_staked;
    mapping(address => uint256) public user_num_stakes;
    uint[] private stake_price_by_day;
    uint256 public daily_award;
    uint256 public total_coin_staked;
    uint256 public deploy_time;
    uint256 public last_award_offset;
    uint256 public day_length;
    uint256 public lock_period;
    uint256 public total_period;
    address public creaticles_address;
    bool public fix_applied;
    uint256 public scale;

    function fix() public {
        // can only call this once
        if (fix_applied == false) {
            console.log('Applying hotfix');
            scale = 100000000000; // a large number to prevent rounding rewards per token down to zero
            // last_award_offset = 0; // recompute first day awards
            last_award_offset = 1;
            delete stake_price_by_day;
            stake_price_by_day.push(0);
            // 908643
            stake_price_by_day.push((100000 * scale) / 908643);
            fix_applied = true;
        }
        else {
            console.log('Called again!');
        }
    }

    function initialize(address _creaticles_address, uint256 _day_length, uint256 _lock_period, uint256 _daily_reward, uint256 _total_period, uint256 _deploy_time) public initializer {
        creaticles_address = _creaticles_address;
        stake_price_by_day.push(0);
        daily_award = _daily_reward;
        total_coin_staked = 0;
        total_period = _total_period;
        day_length = _day_length;
        deploy_time = _deploy_time; // day
        last_award_offset = 0;
        lock_period = _lock_period;
        scale = 1;
        // TODO add end to staking period

        // uint a = 4;
        // uint b = 5;
        // uint c = a - b;
        // console.log(c);
    }

    function hash_of_user_stake(address user, uint256 stake_id) private pure returns (bytes32 hash) {
        return keccak256(abi.encodePacked(user, stake_id));
    }

    function stake(uint256 stake_id, uint256 amount) public returns (uint256 amount_staked) {
        require(stake_id < 10000, "No more than 10000 stakes per user");
        require(block.timestamp <= deploy_time + day_length * total_period, "Cannot stake after end of reward period");
        bytes32 user_hash = hash_of_user_stake(msg.sender, stake_id);

        // add coin to staking - this coin acrues interest each day
        require(amount > 0, "Cannot stake zero coin");
        require(user_coin_staked[user_hash] == 0, "Can only have one stake at once for stake id");
        check_increment_day();

        // if this next statement succeeds, we will have received Creaticles token payment
        IERC20(creaticles_address).transferFrom(msg.sender, address(this), amount);

        total_coin_staked = total_coin_staked + amount;
        user_coin_staked[user_hash] = amount;
        user_time_created[user_hash] = block.timestamp > deploy_time ? block.timestamp : deploy_time;

        // keep track of largest stake id we have seen so far
        uint256 num_stakes = user_num_stakes[msg.sender];
        user_num_stakes[msg.sender] = num_stakes >= stake_id + 1 ? num_stakes : stake_id + 1;

        return amount;
    }

    function unstake(uint256 stake_id, uint256 amount) public returns (uint256 amount_staked) {
        require(stake_id < 10000, "No more than 10000 stakes per user");
        require(scale > 0, "Scale not set, please wait");
        bytes32 user_hash = hash_of_user_stake(msg.sender, stake_id);
        uint256 buy_amount = user_coin_staked[user_hash];

        require(amount <= buy_amount, "Cannot unstake more than you staked");
        require(amount > 0, "Cannot unstake zero coin");

        uint256 profit = 0;

        // remove coin from staking - if longer than lockup period we acrue interest
        check_increment_day();
        if (block.timestamp > deploy_time) {
            // offset is number of days since deployment, rounded down
            uint256 current_offset = (block.timestamp - deploy_time) / day_length;
            uint256 buy_offset = (user_time_created[user_hash] - deploy_time) / day_length;

            uint256 prev_price = stake_price_by_day[buy_offset];
            uint256 current_price = stake_price_by_day[current_offset];

            profit = amount * (current_price - prev_price) / scale;

            if (current_offset - buy_offset < lock_period) {
                profit = 0;  // they did not wait long enough, we simply give them their coin back
            }
        }

        console.log("Sending unstake profit: ", profit);

        user_coin_staked[user_hash] = buy_amount - amount;
        total_coin_staked = total_coin_staked - amount;

        IERC20(creaticles_address).transfer(msg.sender, amount + profit);

        return buy_amount - amount;
    }

    function increment_day() internal {
        // give award to users since we have reached a new day - we award 100k tokens to the community!
        uint256 current_offset = (block.timestamp - deploy_time) / day_length;
        uint256 day_diff = current_offset - last_award_offset;
        
        uint256 reward_per_token = 0;
        if (total_coin_staked > 0) {
            reward_per_token = (daily_award * scale) / total_coin_staked;
        }

        console.log("Old stake price: ", stake_price_by_day[stake_price_by_day.length - 1]);
        for(uint256 i = 0; i < day_diff; i++) {
            uint256 prev_price = stake_price_by_day[stake_price_by_day.length - 1];
            uint256 new_price = prev_price + reward_per_token;
            if (stake_price_by_day.length <= total_period) {
                stake_price_by_day.push(new_price);
            }
            else {
                // once we reach the end of the total period, we stop increasing the daily price (and therefore the profit from withdrawing)
                stake_price_by_day.push(prev_price);
            }
        }
        console.log("New stake price: ", stake_price_by_day[stake_price_by_day.length - 1]);

        last_award_offset = current_offset;
    }

    function number_of_stakes(address user) public view returns (uint256 num_stakes) {
        return user_num_stakes[user];
    }

    function check_increment_day() public {
        // this forces an update of day so we can check interest
        if (block.timestamp >= deploy_time) {
            uint256 current_offset = (block.timestamp - deploy_time) / day_length;
            console.log("Number of days since deployment: ", current_offset);
            if (current_offset > last_award_offset) {
                increment_day();
            }
        }
    }

    function profile(address user, uint256 stake_id) public view returns (uint256 timestamp, uint256 tokens_staked, uint256 interest, bool locked) {
        // show information about staked coin for a user address
        // not that interest information only updates after the first user stakes or unstakes on a given day
        // this function only views interest, does not compute updated interest
        // require(user_coin_staked[user] > 0, "User must have staked coin to view profile");
        require(stake_id < 10000, "No more than 10000 stakes per user");
        require(scale > 0, "Scale not set, please wait");
        bytes32 user_hash = hash_of_user_stake(user, stake_id);

        if (user_coin_staked[user_hash] == 0) {
            return (0, 0, 0, true);
        }

        uint256 buy_time = user_time_created[user_hash];
        uint256 current_user_coin_staked = user_coin_staked[user_hash];

        uint256 profit = 0;
        bool user_locked = true;
        if (block.timestamp > deploy_time) {
            uint256 current_offset = (block.timestamp - deploy_time) / day_length;
            uint256 amount = user_coin_staked[user_hash];

            uint256 buy_offset = (buy_time - deploy_time) / day_length;
            uint256 prev_price = stake_price_by_day[buy_offset];
            // uint256 current_price = stake_price_by_day[current_offset];
            uint256 current_price = stake_price_by_day[stake_price_by_day.length - 1];
            user_locked = (current_offset - buy_offset < lock_period);
            profit = amount * (current_price - prev_price) / scale;
        }

        return (buy_time, current_user_coin_staked, profit, user_locked);
    }
}