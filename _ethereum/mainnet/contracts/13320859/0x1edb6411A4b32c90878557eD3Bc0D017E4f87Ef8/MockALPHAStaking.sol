// SPDX-License-Identifier: Unlicensed

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeMath.sol";

import "./console.sol";

contract MockAlphaStaking {
    using SafeMath for uint256;

    event SetWorker(address worker);
    event Stake(address owner, uint256 share, uint256 amount);
    event Unbond(address owner, uint256 unbondTime, uint256 unbondShare);
    event Withdraw(address owner, uint256 withdrawShare, uint256 withdrawAmount);
    event CancelUnbond(address owner, uint256 unbondTime, uint256 unbondShare);
    event Reward(address worker, uint256 rewardAmount);
    event Extract(address governor, uint256 extractAmount);

    uint256 public constant STATUS_READY = 0;
    uint256 public constant STATUS_UNBONDING = 1;
    uint256 public constant UNBONDING_DURATION = 30 days;
    uint256 public constant WITHDRAW_DURATION = 3 days;

    struct Data {
        uint256 status;
        uint256 share;
        uint256 unbondTime;
        uint256 unbondShare;
    }

    IERC20 public alpha;
    uint256 public totalAlpha;
    uint256 public totalShare;
    mapping(address => Data) public users;

    constructor(IERC20 _alpha) public {
        alpha = _alpha;
    }

    function getStakeValue(address user) external view returns (uint256) {
        uint256 share = users[user].share;
        return share == 0 ? 0 : share.mul(totalAlpha).div(totalShare);
    }

    function stake(uint256 amount) external {
        require(amount >= 1e18, "stake/amount-too-small");
        Data storage data = users[msg.sender];
        if (data.status != STATUS_READY) {
            emit CancelUnbond(msg.sender, data.unbondTime, data.unbondShare);
            data.status = STATUS_READY;
            data.unbondTime = 0;
            data.unbondShare = 0;
        }
        alpha.transferFrom(msg.sender, address(this), amount);
        uint256 share = totalAlpha == 0 ? amount : amount.mul(totalShare).div(totalAlpha);
        totalAlpha = totalAlpha.add(amount);
        totalShare = totalShare.add(share);
        data.share = data.share.add(share);
        emit Stake(msg.sender, share, amount);
    }

    function unbond(uint256 share) external {
        Data storage data = users[msg.sender];
        if (data.status != STATUS_READY) {
            emit CancelUnbond(msg.sender, data.unbondTime, data.unbondShare);
        }
        require(share <= data.share, "unbond/insufficient-share");
        data.status = STATUS_UNBONDING;
        data.unbondTime = block.timestamp;
        data.unbondShare = share;
        emit Unbond(msg.sender, block.timestamp, share);
    }

    function withdraw() external {
        Data storage data = users[msg.sender];
        require(data.status == STATUS_UNBONDING, "withdraw/not-unbonding");
        require(block.timestamp >= data.unbondTime.add(UNBONDING_DURATION), "withdraw/not-valid");
        require(
            block.timestamp < data.unbondTime.add(UNBONDING_DURATION).add(WITHDRAW_DURATION),
            "withdraw/already-expired"
        );
        uint256 share = data.unbondShare;
        uint256 amount = totalAlpha.mul(share).div(totalShare);
        totalAlpha = totalAlpha.sub(amount);
        totalShare = totalShare.sub(share);
        data.share = data.share.sub(share);
        emit Withdraw(msg.sender, share, amount);
        data.status = STATUS_READY;
        data.unbondTime = 0;
        data.unbondShare = 0;
        alpha.transfer(msg.sender, amount);
    }
}
