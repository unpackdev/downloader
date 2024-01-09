// SPDX-License-Identifier: MIT

/*
                    ████████╗██╗  ██╗███████╗
                    ╚══██╔══╝██║  ██║██╔════╝
                       ██║   ███████║█████╗
                       ██║   ██╔══██║██╔══╝
                       ██║   ██║  ██║███████╗
                       ╚═╝   ╚═╝  ╚═╝╚══════╝
██╗  ██╗██╗   ██╗███╗   ███╗ █████╗ ███╗   ██╗ ██████╗ ██╗██████╗ ███████╗
██║  ██║██║   ██║████╗ ████║██╔══██╗████╗  ██║██╔═══██╗██║██╔══██╗██╔════╝
███████║██║   ██║██╔████╔██║███████║██╔██╗ ██║██║   ██║██║██║  ██║███████╗
██╔══██║██║   ██║██║╚██╔╝██║██╔══██║██║╚██╗██║██║   ██║██║██║  ██║╚════██║
██║  ██║╚██████╔╝██║ ╚═╝ ██║██║  ██║██║ ╚████║╚██████╔╝██║██████╔╝███████║
╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝╚═════╝ ╚══════╝


The Humanoids Staking Reward Contract, earning $10 ION per day

*/

pragma solidity =0.8.11;

import "./OwnableTokenAccessControl.sol";
import "./IStakingReward.sol";
import "./IERC20Mint.sol";

contract TheHumanoidsStakingReward is OwnableTokenAccessControl, IStakingReward {
    uint256 public constant REWARD_RATE_PER_DAY = 10 ether;
    uint256 public stakingRewardEndTimestamp = 1736152962;

    mapping(address => uint256) private _stakeData; // packed bits balance:208 timestamp:34 stakedCount:14

    address private constant STAKING_ADDRESS = address(0x3d6a1F739e471c61328Eb8a8D8d998E591C0FD42);
    address private constant TOKEN_ADDRESS = address(0x831dAA3B72576867cD66319259bf022AFB1D9211);


    /// @dev Emitted when `account` claims `amount` of reward.
    event Claim(address indexed account, uint256 amount);


    function setStakingRewardEndTimestamp(uint256 timestamp) external onlyOwner {
        require(stakingRewardEndTimestamp > block.timestamp, "Staking has already ended");
        require(timestamp > block.timestamp, "Must be a time in the future");
        stakingRewardEndTimestamp = timestamp;
    }


    modifier onlyStaking() {
        require(STAKING_ADDRESS == _msgSender(), "Not allowed");
        _;
    }


    function _reward(uint256 timestampFrom, uint256 timestampTo) internal pure returns (uint256) {
        unchecked {
            return ((timestampTo - timestampFrom) * REWARD_RATE_PER_DAY) / 1 days;
        }
    }

    function reward(uint256 timestampFrom, uint256 timestampTo) external view returns (uint256) {
        if (timestampTo > stakingRewardEndTimestamp) {
            timestampTo = stakingRewardEndTimestamp;
        }
        if (timestampFrom < timestampTo) {
            return _reward(timestampFrom, timestampTo);
        }
        return 0;
    }

    function timestampUntilRewardAmount(uint256 targetRewardAmount, uint256 stakedCount, uint256 timestampFrom) public view returns (uint256) {
        require(stakedCount > 0, "stakedCount cannot be zero");
        uint256 div = REWARD_RATE_PER_DAY * stakedCount;
        uint256 duration = ((targetRewardAmount * 1 days) + div - 1) / div; // ceil
        uint256 timestampTo = timestampFrom + duration;
        require(timestampTo <= stakingRewardEndTimestamp, "Cannot get reward amount before staking ends");
        return timestampTo;
    }


    function stakedTokensBalanceOf(address account) external view returns (uint256 stakedCount) {
        stakedCount = _stakeData[account] & 0x3fff;
    }

    function lastClaimTimestampOf(address account) external view returns (uint256 lastClaimTimestamp) {
        lastClaimTimestamp = (_stakeData[account] >> 14) & 0x3ffffffff;
    }

    function rawStakeDataOf(address account) external view returns (uint256 stakeData) {
        stakeData = _stakeData[account];
    }

    function _calculateRewards(uint256 stakeData, uint256 unclaimedBalance) internal view returns (uint256, uint256, uint256) {
        uint256 timestamp = 0;
        uint256 stakedCount = stakeData & 0x3fff;
        if (stakedCount > 0) {
            timestamp = block.timestamp;
            if (timestamp > stakingRewardEndTimestamp) {
                timestamp = stakingRewardEndTimestamp;
            }
            uint256 lastClaimTimestamp = (stakeData >> 14) & 0x3ffffffff;
            if (lastClaimTimestamp < timestamp) {
                unchecked {
                    unclaimedBalance += _reward(lastClaimTimestamp, timestamp) * stakedCount;
                }
            }
        }
        return (unclaimedBalance, timestamp, stakedCount);
    }


    function willStakeTokens(address account, uint16[] calldata tokenIds) external override onlyStaking {
        uint256 stakeData = _stakeData[account];
        (uint256 unclaimedBalance, , uint256 stakedCount) = _calculateRewards(stakeData, stakeData >> 48);
        unchecked {
            _stakeData[account] = (unclaimedBalance << 48) | (block.timestamp << 14) | (stakedCount + tokenIds.length);
        }
    }

    function willUnstakeTokens(address account, uint16[] calldata tokenIds) external override onlyStaking {
        uint256 stakeData = _stakeData[account];
        (uint256 unclaimedBalance, uint256 timestamp, uint256 stakedCount) = _calculateRewards(stakeData, stakeData >> 48);

        uint256 unstakeCount = tokenIds.length;
        if (unstakeCount < stakedCount) {
            unchecked {
                stakedCount -= unstakeCount;
            }
        }
        else {
            stakedCount = 0;
            if (unclaimedBalance == 0) {
                timestamp = 0;
            }
        }

        _stakeData[account] = (unclaimedBalance << 48) | (timestamp << 14) | stakedCount;
    }

    function willBeReplacedByContract(address /*stakingRewardContract*/) external override onlyStaking {
        uint256 timestamp = block.timestamp;
        if (stakingRewardEndTimestamp > timestamp) {
            stakingRewardEndTimestamp = timestamp;
        }
    }

    function didReplaceContract(address /*stakingRewardContract*/) external override onlyStaking {

    }


    function stakeDataOf(address account) external view returns (uint256) {
        uint256 stakeData = _stakeData[account];
        if (stakeData != 0) {
            (uint256 unclaimedBalance, uint256 timestamp, uint256 stakedCount) = _calculateRewards(stakeData, stakeData >> 48);
            stakeData = (unclaimedBalance << 48) | (timestamp << 14) | (stakedCount);
        }
        return stakeData;
    }

    function claimStakeDataFor(address account) external returns (uint256) {
        uint256 stakeData = _stakeData[account];
        if (stakeData != 0) {
            require(_hasAccess(Access.Claim, _msgSender()), "Not allowed to claim");

            (uint256 unclaimedBalance, uint256 timestamp, uint256 stakedCount) = _calculateRewards(stakeData, stakeData >> 48);
            stakeData = (unclaimedBalance << 48) | (timestamp << 14) | (stakedCount);

            delete _stakeData[account];
        }
        return stakeData;
    }


    function _claim(address account, uint256 amount) private {
        if (amount == 0) {
            return;
        }

        uint256 stakeData = _stakeData[account];

        uint256 balance = stakeData >> 48;
        if (balance > amount) {
            unchecked {
                _stakeData[account] = ((balance - amount) << 48) | (stakeData & 0xffffffffffff);
            }
            emit Claim(account, amount);
            return;
        }

        (uint256 unclaimedBalance, uint256 timestamp, uint256 stakedCount) = _calculateRewards(stakeData, balance);

        require(unclaimedBalance >= amount, "Not enough rewards to claim");
        unchecked {
            _stakeData[account] = ((unclaimedBalance - amount) << 48) | (timestamp << 14) | stakedCount;
        }

        emit Claim(account, amount);
    }

    function _transfer(address account, address to, uint256 amount) internal {
        _claim(account, amount);
        IERC20Mint(TOKEN_ADDRESS).mint(to, amount);
    }


    function claimRewardsAmount(uint256 amount) external {
        address account = _msgSender();
        _transfer(account, account, amount);
    }

    function claimRewards() external {
        address account = _msgSender();
        uint256 stakeData = _stakeData[account];
        (uint256 unclaimedBalance, uint256 timestamp, uint256 stakedCount) = _calculateRewards(stakeData, stakeData >> 48);

        require(unclaimedBalance > 0, "Nothing to claim");
        _stakeData[account] = (timestamp << 14) | stakedCount;

        emit Claim(account, unclaimedBalance);
        IERC20Mint(TOKEN_ADDRESS).mint(account, unclaimedBalance);
    }

    // ERC20 compatible functions

    function balanceOf(address account) external view returns (uint256) {
        uint256 stakeData = _stakeData[account];
        (uint256 unclaimedBalance, , ) = _calculateRewards(stakeData, stakeData >> 48);
        return unclaimedBalance;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function transferFrom(address account, address to, uint256 amount) external returns (bool) {
        require(_hasAccess(Access.Transfer, _msgSender()), "Not allowed to transfer");
        _transfer(account, to, amount);
        return true;
    }

    function burn(uint256 amount) external {
        _claim(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) external {
        require(_hasAccess(Access.Burn, _msgSender()), "Not allowed to burn");
        _claim(account, amount);
    }
}
