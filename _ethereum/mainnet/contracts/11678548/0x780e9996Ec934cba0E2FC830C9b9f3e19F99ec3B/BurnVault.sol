//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./IXVIX.sol";
import "./IFloor.sol";
import "./IX2Fund.sol";

contract BurnVault is ReentrancyGuard, IERC20 {
    using SafeMath for uint256;

    string public constant name = "XVIX BurnVault";
    string public constant symbol = "XVIX:BV";
    uint8 public constant decimals = 18;

    uint256 constant PRECISION = 1e30;

    address public token;
    address public floor;
    address public gov;
    address public distributor;

    uint256 public initialDivisor;
    uint256 public _totalSupply;

    mapping (address => uint256) public balances;
    mapping (address => bool) public senders;

    uint256 public cumulativeRewardPerToken;
    mapping (address => uint256) public claimableReward;
    mapping (address => uint256) public previousCumulatedRewardPerToken;

    event Deposit(address account, uint256 amount);
    event Withdraw(address account, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event GovChange(address gov);
    event Claim(address receiver, uint256 amount);

    modifier onlyGov() {
        require(msg.sender == gov, "BurnVault: forbidden");
        _;
    }

    constructor(address _token, address _floor) public {
        token = _token;
        floor = _floor;
        initialDivisor = IXVIX(_token).normalDivisor();
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

    function addSender(address _sender) external onlyGov {
        require(!senders[_sender], "BurnVault: sender already added");
        senders[_sender] = true;
    }

    function removeSender(address _sender) external onlyGov {
        require(senders[_sender], "BurnVault: invalid sender");
        senders[_sender] = false;
    }

    function deposit(uint256 _amount) external nonReentrant {
        require(_amount > 0, "BurnVault: insufficient amount");

        address account = msg.sender;
        _updateRewards(account, true);

        IERC20(token).transferFrom(account, address(this), _amount);

        uint256 scaledAmount = _amount.mul(getDivisor());
        balances[account] = balances[account].add(scaledAmount);
        _totalSupply = _totalSupply.add(scaledAmount);

        emit Deposit(account, _amount);
        emit Transfer(address(0), account, _amount);
    }

    function withdraw(address _receiver, uint256 _amount) external nonReentrant {
        require(_amount > 0, "BurnVault: insufficient amount");

        address account = msg.sender;
        _updateRewards(account, true);
        _withdraw(account, _receiver, _amount);
    }

    function withdrawWithoutDistribution(address _receiver, uint256 _amount) external nonReentrant {
        require(_amount > 0, "BurnVault: insufficient amount");

        address account = msg.sender;
        _updateRewards(account, false);
        _withdraw(account, _receiver, _amount);
    }

    function claim(address _receiver) external nonReentrant {
        address _account = msg.sender;
        _updateRewards(_account, true);

        uint256 rewardToClaim = claimableReward[_account];
        claimableReward[_account] = 0;

        (bool success,) = _receiver.call{value: rewardToClaim}("");
        require(success, "BurnVault: transfer failed");

        emit Claim(_receiver, rewardToClaim);
    }

    function refund(address _receiver) external nonReentrant returns (uint256) {
        require(senders[msg.sender], "BurnVault: forbidden");

        uint256 _toBurn = toBurn();
        if (_toBurn == 0) {
            return 0;
        }

        uint256 refundAmount = IFloor(floor).getRefundAmount(_toBurn);
        if (refundAmount == 0) {
            return 0;
        }

        uint256 ethAmount = IFloor(floor).refund(_receiver, _toBurn);
        return ethAmount;
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply.div(getDivisor());
    }

    function balanceOf(address account) public override view returns (uint256) {
        return balances[account].div(getDivisor());
    }

    function toBurn() public view returns (uint256) {
        uint256 balance = IERC20(token).balanceOf(address(this));
        return balance.sub(totalSupply());
    }

    function getDivisor() public view returns (uint256) {
        uint256 normalDivisor = IXVIX(token).normalDivisor();
        uint256 _initialDivisor = initialDivisor;
        uint256 diff = normalDivisor.sub(_initialDivisor).div(2);
        return _initialDivisor.add(diff);
    }

    // empty implementation, BurnVault tokens are non-transferrable
    function transfer(address /* recipient */, uint256 /* amount */) public override returns (bool) {
        revert("BurnVault: non-transferrable");
    }

    // empty implementation, BurnVault tokens are non-transferrable
    function allowance(address /* owner */, address /* spender */) public view virtual override returns (uint256) {
        return 0;
    }

    // empty implementation, BurnVault tokens are non-transferrable
    function approve(address /* spender */, uint256 /* amount */) public virtual override returns (bool) {
        revert("BurnVault: non-transferrable");
    }

    // empty implementation, BurnVault tokens are non-transferrable
    function transferFrom(address /* sender */, address /* recipient */, uint256 /* amount */) public virtual override returns (bool) {
        revert("BurnVault: non-transferrable");
    }

    function _withdraw(address _account, address _receiver, uint256 _amount) private {
        uint256 scaledAmount = _amount.mul(getDivisor());
        require(balances[_account] >= scaledAmount, "BurnVault: insufficient balance");

        balances[_account] = balances[_account].sub(scaledAmount);
        _totalSupply = _totalSupply.sub(scaledAmount);

        IERC20(token).transfer(_receiver, _amount);

        emit Withdraw(_account, _amount);
        emit Transfer(_account, address(0), _amount);
    }

    function _updateRewards(address _account, bool _distribute) private {
        uint256 blockReward;

        if (_distribute && distributor != address(0)) {
            blockReward = IX2Fund(distributor).distribute();
        }

        uint256 _cumulativeRewardPerToken = cumulativeRewardPerToken;
        // only update cumulativeRewardPerToken when there are stakers, i.e. when _totalSupply > 0
        // if blockReward == 0, then there will be no change to cumulativeRewardPerToken
        if (_totalSupply > 0 && blockReward > 0) {
            _cumulativeRewardPerToken = _cumulativeRewardPerToken.add(blockReward.mul(PRECISION).div(_totalSupply));
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
