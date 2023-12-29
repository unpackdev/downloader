// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract DudeStake is Ownable {
    using SafeMath for uint256;

    struct StakeInfo {
        uint256 amount;
        uint256 endAt;
        uint256 total;
        uint256 earned;
    }

    mapping(address => StakeInfo) public stakes;

    IERC20 public token;
    uint256 public apr = 55;
    uint256 public fee = 4;
    address public pool;
    uint256 public stakeTime = 7 days;
    uint256 public minimal = 1000 * 1e18;

    uint256 public holderShare = 4;
    address[] public holders;

    constructor(IERC20 token_) Ownable() {
        token = token_;
        pool = msg.sender;
    }

    function setFee(uint256 _fee) external onlyOwner {
        require(fee <= 10, "over fee");
        fee = _fee;
    }

    function setHolderShare(uint256 _holderShare) external onlyOwner {
        holderShare = _holderShare;
    }

    function setAPR(uint256 _apr) external onlyOwner {
        apr = _apr;
    }

    function stake(uint256 amount) public {
        require(amount >= minimal, "too small");
        uint256 oldBalance = token.balanceOf(pool);
        require(token.transferFrom(msg.sender, pool, amount), "can not transfer");
        uint256 newBalance = token.balanceOf(pool);
        uint256 stakeAmount = newBalance.sub(oldBalance);

        StakeInfo storage info = stakes[msg.sender];
        info.amount = info.amount.add(stakeAmount);
        info.endAt = block.timestamp + stakeTime;
        info.total = info.total.add(stakeAmount);
    }

    function unStake() public {
        StakeInfo storage info = stakes[msg.sender];

        require(info.amount > 0, "can not un-stake");

        uint256 unStakeAmount;
        uint256 holderAmount;

        if (block.timestamp <= info.endAt) {
            uint256 feeAmount = info.amount.mul(fee).div(100);
            holderAmount = feeAmount.mul(holderShare).div(100);
            unStakeAmount = info.amount.sub(feeAmount);
        } else {
            uint256 reward = info.amount.mul(stakeTime).div(365 days).mul(apr).div(100);
            holderAmount = reward.mul(holderShare).div(100);
            unStakeAmount = info.amount.add(reward.sub(holderShare));
            info.earned = info.earned.add(reward.sub(holderShare));
        }

        require(token.transferFrom(pool, msg.sender, unStakeAmount), "can not transfer");
        require(token.transferFrom(pool, address(this), holderAmount), "can not transfer");

        info.amount = 0;
        info.endAt = 0;
    }

    function setHolders(address[] memory _holders) public onlyOwner {
        holders = _holders;
    }

    function airdrop() public onlyOwner {
        uint256 len = holders.length;
        uint256 holderAmount = token.balanceOf(address(this));
        require(len > 0 && holderAmount > 0, "airdrop");
        uint256 amount = holderAmount.div(len);
        for (uint256 i=1; i < len; i++) {
            require(token.transfer(holders[i], amount), "can not transfer");
            holderAmount = holderAmount.sub(amount);
        }
        token.transfer(holders[0], holderAmount);
    }
}