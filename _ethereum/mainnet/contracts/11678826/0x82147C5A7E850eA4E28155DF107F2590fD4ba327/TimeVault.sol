//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./IXVIX.sol";
import "./ITimeVault.sol";
import "./IX2Fund.sol";

contract TimeVault is ITimeVault, IERC20, ReentrancyGuard {
    using SafeMath for uint256;

    string public constant name = "XVIX TimeVault";
    string public constant symbol = "XVIX:TV";
    uint8 public constant decimals = 18;

    uint256 constant PRECISION = 1e30;

    uint256 public constant WITHDRAWAL_DELAY = 7 days;
    uint256 public constant WITHDRAWAL_WINDOW = 48 hours;

    address public token;
    address public gov;
    address public distributor;

    uint256 public override totalSupply;

    mapping (address => uint256) public balances;
    mapping (address => uint256) public withdrawalTimestamps;
    mapping (address => uint256) public withdrawalAmounts;
    mapping (uint256 => uint256) public override withdrawalSlots;

    uint256 public cumulativeRewardPerToken;
    mapping (address => uint256) public claimableReward;
    mapping (address => uint256) public previousCumulatedRewardPerToken;

    event Deposit(address account, uint256 amount);
    event BeginWithdrawal(address account, uint256 amount);
    event Withdraw(address account, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event GovChange(address gov);
    event Claim(address receiver, uint256 amount);

    modifier onlyGov() {
        require(msg.sender == gov, "TimeVault: forbidden");
        _;
    }

    constructor(address _token) public {
        token = _token;
        gov = msg.sender;
    }

    receive() external payable {}

    function setGov(address _gov) external onlyGov {
        gov = _gov;
        emit GovChange(_gov);
    }

    function setDistributor(address _distributor) external onlyGov {
        distributor = _distributor;
    }

    function deposit(uint256 _amount) external nonReentrant {
        require(_amount > 0, "TimeVault: insufficient amount");
        address account = msg.sender;
        _updateRewards(account, true);

        IERC20(token).transferFrom(account, address(this), _amount);
        balances[account] = balances[account].add(_amount);
        totalSupply = totalSupply.add(_amount);

        emit Deposit(account, _amount);
        emit Transfer(address(0), account, _amount);
    }

    function beginWithdrawal(uint256 _amount) external nonReentrant {
        address account = msg.sender;
        require(_amount > 0, "TimeVault: insufficient amount");
        require(_amount <= balanceOf(account), "TimeVault: insufficient balance");

        _decreaseWithdrawalSlot(withdrawalTimestamps[account], withdrawalAmounts[account]);

        uint256 time = block.timestamp.add(WITHDRAWAL_DELAY);
        withdrawalTimestamps[account] = time;
        withdrawalAmounts[account] = _amount;

        _increaseWithdrawalSlot(time, _amount);
        emit BeginWithdrawal(account, _amount);
    }

    function withdraw(address _receiver) external nonReentrant {
        address account = msg.sender;
        _updateRewards(account, true);
        _withdraw(account, _receiver);
    }

    function withdrawWithoutDistribution(address _receiver) external nonReentrant {
        address account = msg.sender;
        _updateRewards(account, false);
        _withdraw(account, _receiver);
    }

    function claim(address _receiver) external nonReentrant {
        address _account = msg.sender;
        _updateRewards(_account, true);

        uint256 rewardToClaim = claimableReward[_account];
        claimableReward[_account] = 0;

        (bool success,) = _receiver.call{value: rewardToClaim}("");
        require(success, "TimeVault: transfer failed");

        emit Claim(_receiver, rewardToClaim);
    }

    function getWithdrawalSlot(uint256 _time) public pure returns (uint256) {
        return _time.div(WITHDRAWAL_WINDOW);
    }

    function balanceOf(address account) public override view returns (uint256) {
        return balances[account];
    }

    // empty implementation, TimeVault tokens are non-transferrable
    function transfer(address /* recipient */, uint256 /* amount */) public override returns (bool) {
        revert("TimeVault: non-transferrable");
    }

    // empty implementation, TimeVault tokens are non-transferrable
    function allowance(address /* owner */, address /* spender */) public view virtual override returns (uint256) {
        return 0;
    }

    // empty implementation, TimeVault tokens are non-transferrable
    function approve(address /* spender */, uint256 /* amount */) public virtual override returns (bool) {
        revert("TimeVault: non-transferrable");
    }

    // empty implementation, TimeVault tokens are non-transferrable
    function transferFrom(address /* sender */, address /* recipient */, uint256 /* amount */) public virtual override returns (bool) {
        revert("TimeVault: non-transferrable");
    }

    function _withdraw(address _account, address _receiver) private {
        uint256 currentTime = block.timestamp;
        uint256 minTime = withdrawalTimestamps[_account];
        require(minTime != 0, "TimeVault: withdrawal not initiated");
        require(currentTime > minTime, "TimeVault: withdrawal timing not reached");

        uint256 maxTime = minTime.add(WITHDRAWAL_WINDOW);
        require(currentTime < maxTime, "TimeVault: withdrawal window already passed");

        uint256 amount = withdrawalAmounts[_account];
        require(amount <= balanceOf(_account), "TimeVault: insufficient amount");

        _decreaseWithdrawalSlot(minTime, amount);

        withdrawalTimestamps[_account] = 0;
        withdrawalAmounts[_account] = 0;

        balances[_account] = balances[_account].sub(amount);
        totalSupply = totalSupply.sub(amount);

        IXVIX(token).rebase();
        IERC20(token).transfer(_receiver, amount);

        emit Withdraw(_account, amount);
        emit Transfer(_account, address(0), amount);
    }

    function _increaseWithdrawalSlot(uint256 _time, uint256 _amount) private {
        uint256 slot = getWithdrawalSlot(_time);
        withdrawalSlots[slot] = withdrawalSlots[slot].add(_amount);
    }

    function _decreaseWithdrawalSlot(uint256 _time, uint256 _amount) private {
        if (_time == 0 || _amount == 0) { return; }
        uint256 slot = getWithdrawalSlot(_time);
        if (_amount > withdrawalSlots[slot]) {
            withdrawalSlots[slot] = 0;
            return;
        }
        withdrawalSlots[slot] = withdrawalSlots[slot].sub(_amount);
    }

    function _updateRewards(address _account, bool _distribute) private {
        uint256 blockReward;

        if (_distribute && distributor != address(0)) {
            blockReward = IX2Fund(distributor).distribute();
        }

        uint256 _cumulativeRewardPerToken = cumulativeRewardPerToken;
        // only update cumulativeRewardPerToken when there are stakers, i.e. when totalSupply > 0
        // if blockReward == 0, then there will be no change to cumulativeRewardPerToken
        if (totalSupply > 0 && blockReward > 0) {
            _cumulativeRewardPerToken = _cumulativeRewardPerToken.add(blockReward.mul(PRECISION).div(totalSupply));
            cumulativeRewardPerToken = _cumulativeRewardPerToken;
        }

        // cumulativeRewardPerToken can only increase
        // so if cumulativeRewardPerToken is zero, it means there are no rewards yet
        if (_cumulativeRewardPerToken == 0) {
            return;
        }

        uint256 _previousCumulatedReward = previousCumulatedRewardPerToken[_account];
        uint256 _claimableReward = claimableReward[_account].add(
            uint256(balances[_account]).mul(_cumulativeRewardPerToken.sub(_previousCumulatedReward)).div(PRECISION)
        );

        claimableReward[_account] = _claimableReward;
        previousCumulatedRewardPerToken[_account] = _cumulativeRewardPerToken;
    }
}
