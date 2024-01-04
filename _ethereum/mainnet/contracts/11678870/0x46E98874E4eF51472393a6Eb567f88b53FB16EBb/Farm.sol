//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./IX2Fund.sol";

contract Farm is ReentrancyGuard, IERC20 {
    using SafeMath for uint256;

    string public constant name = "XVIX XLGE Farm";
    string public constant symbol = "XLGE:FARM";
    uint8 public constant decimals = 18;

    uint256 constant PRECISION = 1e30;

    address public token;
    address public gov;
    address public distributor;

    uint256 public override totalSupply;

    mapping (address => uint256) public balances;

    uint256 public cumulativeRewardPerToken;
    mapping (address => uint256) public claimableReward;
    mapping (address => uint256) public previousCumulatedRewardPerToken;

    event Deposit(address account, uint256 amount);
    event Withdraw(address account, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event GovChange(address gov);
    event Claim(address receiver, uint256 amount);

    modifier onlyGov() {
        require(msg.sender == gov, "Farm: forbidden");
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

    function deposit(uint256 _amount, address _receiver) external nonReentrant {
        require(_amount > 0, "Farm: insufficient amount");

        _updateRewards(_receiver, true);

        IERC20(token).transferFrom(msg.sender, address(this), _amount);

        balances[_receiver] = balances[_receiver].add(_amount);
        totalSupply = totalSupply.add(_amount);

        emit Deposit(_receiver, _amount);
        emit Transfer(address(0), _receiver, _amount);
    }

    function withdraw(address _receiver, uint256 _amount) external nonReentrant {
        require(_amount > 0, "Farm: insufficient amount");

        address account = msg.sender;
        _updateRewards(account, true);
        _withdraw(account, _receiver, _amount);
    }

    function withdrawWithoutDistribution(address _receiver, uint256 _amount) external nonReentrant {
        require(_amount > 0, "Farm: insufficient amount");

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
        require(success, "Farm: transfer failed");

        emit Claim(_receiver, rewardToClaim);
    }

    function balanceOf(address account) public override view returns (uint256) {
        return balances[account];
    }

    // empty implementation, Farm tokens are non-transferrable
    function transfer(address /* recipient */, uint256 /* amount */) public override returns (bool) {
        revert("Farm: non-transferrable");
    }

    // empty implementation, Farm tokens are non-transferrable
    function allowance(address /* owner */, address /* spender */) public view virtual override returns (uint256) {
        return 0;
    }

    // empty implementation, Farm tokens are non-transferrable
    function approve(address /* spender */, uint256 /* amount */) public virtual override returns (bool) {
        revert("Farm: non-transferrable");
    }

    // empty implementation, Farm tokens are non-transferrable
    function transferFrom(address /* sender */, address /* recipient */, uint256 /* amount */) public virtual override returns (bool) {
        revert("Farm: non-transferrable");
    }

    function _withdraw(address _account, address _receiver, uint256 _amount) private {
        require(balances[_account] >= _amount, "Farm: insufficient balance");

        balances[_account] = balances[_account].sub(_amount);
        totalSupply = totalSupply.sub(_amount);

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
