// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Initializable.sol";

contract DFDStaking is Initializable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    event SetWorker(address worker);
    event Stake(address owner, uint share, uint amount);
    event Unbond(address owner, uint unbondTime, uint unbondShare);
    event Withdraw(address owner, uint withdrawShare, uint withdrawAmount);
    event CancelUnbond(address owner, uint unbondTime, uint unbondShare);
    event Reward(address worker, uint rewardAmount);
    event Extract(address governor, uint extractAmount);

    uint public constant STATUS_READY = 0;
    uint public constant STATUS_UNBONDING = 1;

    uint public unbonding_duration = 7 days;
    uint public withdraw_duration = 1 days;
    address public migrator;

    struct Data {
        uint status;
        uint share;
        uint unbondTime;
        uint unbondShare;
    }

    IERC20 public immutable dfd = IERC20(0x20c36f062a31865bED8a5B1e512D9a1A20AA333A);
    address public governor;
    address public pendingGovernor;
    address public worker;
    uint public totalDfd;
    uint public totalShare;
    mapping(address => Data) public users;

    modifier onlyGov() {
        require(msg.sender == governor, 'onlyGov/not-governor');
        _;
    }

    modifier onlyWorker() {
        require(msg.sender == worker || msg.sender == governor, 'onlyWorker/not-worker');
        _;
    }

    function initialize(address _governor, address _migrator) external initializer {
        governor = _governor;
        migrator = _migrator;
    }

    function setWorker(address _worker) external onlyGov {
        worker = _worker;
        emit SetWorker(_worker);
    }

    function setPendingGovernor(address _pendingGovernor) external onlyGov {
        pendingGovernor = _pendingGovernor;
    }

    function acceptGovernor() external {
        require(msg.sender == pendingGovernor, 'acceptGovernor/not-pending');
        pendingGovernor = address(0);
        governor = msg.sender;
    }

    function getStakeValue(address user) external view returns (uint) {
        uint share = users[user].share;
        return share == 0 ? 0 : share.mul(totalDfd).div(totalShare);
    }

    function stake(uint amount) external nonReentrant {
        _stake(amount, msg.sender);
    }

    function stakeFor(uint amount, address user) external nonReentrant {
        require(msg.sender == migrator, "stakeFor/no-auth");
        _stake(amount, user);
    }

    function _stake(uint amount, address user) internal {
        require(amount >= 1e18, 'stake/amount-too-small');
        Data storage data = users[user];
        if (data.status != STATUS_READY) {
            emit CancelUnbond(user, data.unbondTime, data.unbondShare);
            data.status = STATUS_READY;
            data.unbondTime = 0;
            data.unbondShare = 0;
        }
        dfd.safeTransferFrom(msg.sender, address(this), amount);
        uint share = totalDfd == 0 ? amount : amount.mul(totalShare).div(totalDfd);
        totalDfd = totalDfd.add(amount);
        totalShare = totalShare.add(share);
        data.share = data.share.add(share);
        emit Stake(user, share, amount);
    }

    function unbond(uint share) external nonReentrant {
        Data storage data = users[msg.sender];
        if (data.status != STATUS_READY) {
            emit CancelUnbond(msg.sender, data.unbondTime, data.unbondShare);
        }
        require(share <= data.share, 'unbond/insufficient-share');
        data.status = STATUS_UNBONDING;
        data.unbondTime = block.timestamp;
        data.unbondShare = share;
        emit Unbond(msg.sender, block.timestamp, share);
    }

    function withdraw() external nonReentrant {
        Data storage data = users[msg.sender];
        require(data.status == STATUS_UNBONDING, 'withdraw/not-unbonding');
        require(block.timestamp >= data.unbondTime.add(unbonding_duration), 'withdraw/not-valid');
        require(
            block.timestamp < data.unbondTime.add(unbonding_duration).add(withdraw_duration),
            'withdraw/already-expired'
        );
        uint share = data.unbondShare;
        uint amount = totalDfd.mul(share).div(totalShare);
        totalDfd = totalDfd.sub(amount);
        totalShare = totalShare.sub(share);
        data.share = data.share.sub(share);
        emit Withdraw(msg.sender, share, amount);
        data.status = STATUS_READY;
        data.unbondTime = 0;
        data.unbondShare = 0;
        dfd.safeTransfer(msg.sender, amount);
        require(totalDfd >= 1e18, 'withdraw/too-low-total-dfd');
    }

    function reward(uint amount) external onlyWorker {
        require(totalShare >= 1e18, 'reward/share-too-small');
        dfd.safeTransferFrom(msg.sender, address(this), amount);
        totalDfd = totalDfd.add(amount);
        emit Reward(msg.sender, amount);
    }

    function skim(uint amount) external onlyGov {
        dfd.safeTransfer(msg.sender, amount);
        require(dfd.balanceOf(address(this)) >= totalDfd, 'skim/not-enough-balance');
    }

    function extract(uint amount) external onlyGov {
        totalDfd = totalDfd.sub(amount);
        dfd.safeTransfer(msg.sender, amount);
        require(totalDfd >= 1e18, 'extract/too-low-total-dfd');
        emit Extract(msg.sender, amount);
    }

    function setUnbondingDuration(uint _duration) external onlyGov {
        unbonding_duration = _duration;
    }

    function setWithdrawalDuration(uint _duration) external onlyGov {
        withdraw_duration = _duration;
    }
}
