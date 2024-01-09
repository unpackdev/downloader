// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "ERC20.sol";

contract StakingPool is Context, Ownable, ReentrancyGuard {
    // constants
    address public mainToken;
    address public lpToken;
    address public rewardToken;

    // current balance of each token
    struct Staking {
        uint256 mainTokenAmt;
        uint256 lpTokenAmt;
    }

    mapping(address => Staking) private _balance;

    // rewards for staking
    mapping(address => uint256) private _nextUnpaidDay;
    mapping(address => uint256) private _rewards;

    // everything is paid out at end of day
    uint256 private _rewardSupply;
    uint256 public rewardEnd;
    uint256 public dailyPayout;

    uint8 public unstakeFee = 3;

    mapping(uint256 => uint256) private dailyRewardRate; // values in Autowei for better precision
    uint256 private _nextDayToUpdate;
    Staking private _totalStaked; // total staked across all users

    constructor(
        address _mainToken,
        address _lpToken,
        address _rewardToken
    ) {
        mainToken = _mainToken;
        lpToken = _lpToken;
        rewardToken = _rewardToken;
    }

    function setUnstakeFee(uint8 _feePercent) public onlyOwner {
        require(_feePercent < 100, "Percent must be less than 100.");
        unstakeFee = _feePercent;
    }

    function stake(bool isLpToken, uint256 amount) public nonReentrant {
        _stake(isLpToken, _msgSender(), amount);
    }

    function _stake(
        bool isLpToken,
        address account,
        uint256 amount
    ) private {
        _updateRewards(account); // also calls _updateDailyRates()
        if (isLpToken) {
            IERC20(lpToken).transferFrom(account, address(this), amount);
            _balance[account].lpTokenAmt += amount;
            _totalStaked.lpTokenAmt += amount;
        } else {
            IERC20(mainToken).transferFrom(account, address(this), amount);
            _balance[account].mainTokenAmt += amount;
            _totalStaked.mainTokenAmt += amount;
        }
    }

    function balanceOf(address account)
        public
        view
        returns (uint256 mainTokenBal, uint256 lpTokenBal)
    {
        return (_balance[account].mainTokenAmt, _balance[account].lpTokenAmt);
    }

    function withdraw(bool isLpToken, uint256 amount) public nonReentrant {
        _updateRewards(_msgSender()); // also calls _updateDailyRates()
        if (isLpToken) {
            require(
                _balance[_msgSender()].lpTokenAmt >= amount,
                "Amount exceeds token balance"
            );

            IERC20(lpToken).transfer(
                _msgSender(),
                (amount * (100 - unstakeFee)) / 100
            );
            _balance[_msgSender()].lpTokenAmt -= amount;
            _totalStaked.lpTokenAmt -= amount;
        } else {
            require(
                _balance[_msgSender()].mainTokenAmt >= amount,
                "Amount exceeds token balance"
            );
            IERC20(mainToken).transfer(
                _msgSender(),
                (amount * (100 - unstakeFee)) / 100
            );
            _balance[_msgSender()].mainTokenAmt -= amount;
            _totalStaked.mainTokenAmt -= amount;
        }
    }

    function rewards(address account) public view returns (uint256) {
        // waiting for user's first stake
        if (_nextUnpaidDay[account] == 0) return 0;
        uint256 today = block.timestamp / 86400;
        uint256 start = _nextUnpaidDay[account];
        uint256 staked = _balance[account].mainTokenAmt +
            (_balance[account].lpTokenAmt * 4);
        uint256 totalRewards = _rewards[account];
        for (uint256 day = start; day < today; day++)
            totalRewards += (staked * _rewardRate(day)) / 1e18;
        return totalRewards;
    }

    function withdrawRewards() public nonReentrant {
        _updateRewards(_msgSender());
        uint256 amount = _rewards[_msgSender()];
        require(amount > 0, "Nothing to withdraw.");
        _rewards[_msgSender()] = 0;
        IERC20(rewardToken).transfer(_msgSender(), amount);
    }

    function addRewards(uint256 duration, uint256 amount) public nonReentrant {
        require(duration > 0, "Duration cannot be 0.");
        require(duration < 1000, "Duration should be in days.");
        _updateDailyRates(); // also updates the rewards available vs. waiting to be claimed
        uint256 today = block.timestamp / 86400;
        uint256 end = today + duration;
        if (end > rewardEnd) rewardEnd = end;
        IERC20(rewardToken).transferFrom(_msgSender(), address(this), amount);
        _rewardSupply += amount;
        dailyPayout = _rewardSupply / (rewardEnd - today);
        if (_nextDayToUpdate == 0) _nextDayToUpdate = today;
    }

    function withdrawFees() public onlyOwner {
        IERC20(mainToken).transfer(
            _msgSender(),
            IERC20(mainToken).balanceOf(address(this)) -
                _totalStaked.mainTokenAmt
        );
        IERC20(lpToken).transfer(
            _msgSender(),
            IERC20(lpToken).balanceOf(address(this)) - _totalStaked.lpTokenAmt
        );
    }

    // make this public to somewhat reduce user gas costs?
    function _updateDailyRates() private {
        if (
            rewardEnd <= _nextDayToUpdate ||
            (_totalStaked.mainTokenAmt == 0 && _totalStaked.lpTokenAmt == 0)
        )
            // The current reward pool has been completed.
            // Nothing left to pay out before another addReward.
            return;
        uint256 today = block.timestamp / 86400;
        uint256 currentRewardRate = (dailyPayout * 1e18) /
            (_totalStaked.mainTokenAmt + (_totalStaked.lpTokenAmt * 4));
        for (uint256 day = _nextDayToUpdate; day < today; day++)
            if (day >= rewardEnd) dailyRewardRate[day] = 0;
            else dailyRewardRate[day] = currentRewardRate;

        uint256 end = today;
        if (today > rewardEnd) end = rewardEnd;
        uint256 totalRewarded = dailyPayout * (end - _nextDayToUpdate);
        _nextDayToUpdate = today;
        _rewardSupply -= totalRewarded;
    }

    function _updateRewards(address account) private {
        _updateDailyRates();
        _rewards[account] = rewards(account);
        _nextUnpaidDay[account] = block.timestamp / 86400;
    }

    function _rewardRate(uint256 day) private view returns (uint256) {
        if (day < _nextDayToUpdate) return dailyRewardRate[day];
        if (
            day >= rewardEnd ||
            (_totalStaked.mainTokenAmt == 0 && _totalStaked.lpTokenAmt == 0)
        ) return 0;
        else
            return
                (dailyPayout * 1e18) /
                (_totalStaked.mainTokenAmt + (_totalStaked.lpTokenAmt * 4));
    }
}
