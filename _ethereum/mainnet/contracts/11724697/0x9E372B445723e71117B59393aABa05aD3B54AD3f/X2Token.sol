// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

import "./IX2Fund.sol";
import "./IX2Market.sol";
import "./IX2Token.sol";

// rewards code adapated from https://github.com/trusttoken/smart-contracts/blob/master/contracts/truefi/TrueFarm.sol
contract X2Token is IERC20, IX2Token, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Ledger {
        uint128 balance;
        uint128 cost;
    }

    // max uint128 has 38 digits
    // the initial divisor has 10 digits
    // each 1 wei of rewards will increase cumulativeRewardPerToken by
    // 1*10^10 (PRECISION 10^20 / divisor 10^10)
    // assuming a supply of only 1 wei of X2Tokens
    // if the reward token has 18 decimals, total rewards of up to
    // 1 billion reward tokens is supported
    // max uint96 has 28 digits, so max claimable rewards also supports
    // 1 billion reward tokens
    struct Reward {
        uint128 previousCumulativeRewardPerToken;
        uint96 claimable;
        uint32 lastBoughtAt;
    }

    uint256 constant HOLDING_TIME = 10 minutes;
    uint256 constant PRECISION = 1e20;
    uint256 constant MAX_BALANCE = uint128(-1);
    uint256 constant MAX_REWARD = uint96(-1);
    uint256 constant MAX_CUMULATIVE_REWARD = uint128(-1);
    uint256 constant MAX_QUANTITY_POINTS = 1e30;

    string public name = "X2";
    string public symbol = "X2";
    uint8 public constant decimals = 18;

    // _totalSupply also tracks totalStaked
    uint256 public override _totalSupply;

    address public override market;
    address public factory;
    address public override distributor;
    address public override rewardToken;

    // ledgers track balances and costs
    mapping (address => Ledger) public ledgers;
    mapping (address => mapping (address => uint256)) public allowances;

    // track previous cumulated rewards and claimable rewards for accounts
    mapping(address => Reward) public rewards;
    // track overall cumulative rewards
    uint256 public override cumulativeRewardPerToken;

    bool public isInitialized;

    event Claim(address receiver, uint256 amount);

    modifier onlyFactory() {
        require(msg.sender == factory, "X2Token: forbidden");
        _;
    }

    modifier onlyMarket() {
        require(msg.sender == market, "X2Token: forbidden");
        _;
    }

    receive() external payable {}

    function initialize(address _factory, address _market) public {
        require(!isInitialized, "X2Token: already initialized");
        isInitialized = true;
        factory = _factory;
        market = _market;
    }

    function setDistributor(address _distributor, address _rewardToken) external override onlyFactory {
        distributor = _distributor;
        rewardToken = _rewardToken;
    }

    function setInfo(string memory _name, string memory _symbol) external override onlyFactory {
        name = _name;
        symbol = _symbol;
    }

    function mint(address _account, uint256 _amount, uint256 _divisor) external override onlyMarket {
        _mint(_account, _amount, _divisor);
    }

    function burn(address _account, uint256 _burnPoints, bool _distribute) external override onlyMarket returns (uint256) {
        return _burn(_account, _burnPoints, _distribute);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply.div(getDivisor());
    }

    function transfer(address _recipient, uint256 _amount) external override returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) external view override returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) external override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        uint256 nextAllowance = allowances[_sender][msg.sender].sub(_amount, "X2Token: transfer amount exceeds allowance");
        _approve(_sender, msg.sender, nextAllowance);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    function claim(address _receiver) external nonReentrant {
        address _account = msg.sender;
        uint256 cachedTotalSupply = _totalSupply;
        _updateRewards(_account, cachedTotalSupply, true, false);

        Reward storage reward = rewards[_account];
        uint256 rewardToClaim = reward.claimable;
        reward.claimable = 0;

        IERC20(rewardToken).transfer(_receiver, rewardToClaim);

        emit Claim(_receiver, rewardToClaim);
    }

    function getDivisor() public override view returns (uint256) {
        return IX2Market(market).getDivisor(address(this));
    }

    function lastBoughtAt(address _account) public override view returns (uint256) {
        return uint256(rewards[_account].lastBoughtAt);
    }

    function hasPendingPurchase(address _account) public view returns (bool) {
        return lastBoughtAt(_account) > block.timestamp.sub(HOLDING_TIME);
    }

    function getPendingProfit(address _account) public override view returns (uint256) {
        if (!hasPendingPurchase(_account)) {
            return 0;
        }

        uint256 balance = uint256(ledgers[_account].balance).div(getDivisor());
        uint256 cost = costOf(_account);
        return balance <= cost ? 0 : balance.sub(cost);
    }

    function balanceOf(address _account) public view override returns (uint256) {
        uint256 balance = uint256(ledgers[_account].balance).div(getDivisor());
        if (!hasPendingPurchase(_account)) {
            return balance;
        }
        uint256 cost = costOf(_account);
        return balance < cost ? balance : cost;
    }

    function _balanceOf(address _account) public view override returns (uint256) {
        return uint256(ledgers[_account].balance);
    }

    function costOf(address _account) public override view returns (uint256) {
        return uint256(ledgers[_account].cost);
    }

    function getReward(address _account) public override view returns (uint256) {
        return uint256(rewards[_account].claimable);
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        require(!hasPendingPurchase(_sender), "X2Token: holding time not yet passed");
        require(_sender != address(0), "X2Token: transfer from the zero address");
        require(_recipient != address(0), "X2Token: transfer to the zero address");

        uint256 divisor = getDivisor();
        _decreaseBalance(_sender, _amount, divisor, true);
        _increaseBalance(_recipient, _amount, divisor, false);

        emit Transfer(_sender, _recipient, _amount);
    }

    function _mint(address _account, uint256 _amount, uint256 _divisor) private {
        require(_account != address(0), "X2Token: mint to the zero address");

        _increaseBalance(_account, _amount, _divisor, true);

        emit Transfer(address(0), _account, _amount);
    }

    function _burn(address _account, uint256 _burnPoints, bool _distribute) private returns (uint256) {
        require(_account != address(0), "X2Token: burn from the zero address");

        uint256 divisor = getDivisor();

        Ledger memory ledger = ledgers[_account];
        uint256 balance = uint256(ledger.balance).div(divisor);
        uint256 amount = balance.mul(_burnPoints).div(MAX_QUANTITY_POINTS);
        uint256 scaledAmount = amount;

        if (hasPendingPurchase(_account) && balance > ledger.cost) {
            // if there is a pending purchase and the user's balance
            // is greater than their cost, it means they have a pending profit
            // we scale up the amount to burn the proportional amount of
            // pending profit
            amount = uint256(ledger.cost).mul(_burnPoints).div(MAX_QUANTITY_POINTS);
            scaledAmount = amount.mul(balance).div(ledger.cost);
        }

        _decreaseBalance(_account, scaledAmount, divisor, _distribute);

        emit Transfer(_account, address(0), amount);

        return amount;
    }

    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "X2Token: approve from the zero address");
        require(_spender != address(0), "X2Token: approve to the zero address");

        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function _increaseBalance(address _account, uint256 _amount, uint256 _divisor, bool _updateLastBoughtAt) private {
        if (_amount == 0) { return; }

        uint256 cachedTotalSupply = _totalSupply;
        _updateRewards(_account, cachedTotalSupply, true, _updateLastBoughtAt);

        uint256 scaledAmount = _amount.mul(_divisor);
        Ledger memory ledger = ledgers[_account];

        uint256 nextBalance = uint256(ledger.balance).add(scaledAmount);
        require(nextBalance < MAX_BALANCE, "X2Token: balance limit exceeded");

        uint256 cost = uint256(ledger.cost).add(_amount);
        require(cost < MAX_BALANCE, "X2Token: cost limit exceeded");

        ledgers[_account] = Ledger(
            uint128(nextBalance),
            uint128(cost)
        );

        _totalSupply = cachedTotalSupply.add(scaledAmount);
    }

    function _decreaseBalance(address _account, uint256 _amount, uint256 _divisor, bool _distribute) private {
        if (_amount == 0) { return; }

        uint256 cachedTotalSupply = _totalSupply;
        _updateRewards(_account, cachedTotalSupply, _distribute, false);

        uint256 scaledAmount = _amount.mul(_divisor);
        Ledger memory ledger = ledgers[_account];

        // since _amount is not zero, so scaledAmount should not be zero
        // if ledger.balance is zero, then uint256(ledger.balance).sub(scaledAmount)
        // should fail, so we can calculate cost with ...div(ledger.balance)
        // as ledger.balance should not be zero
        uint256 nextBalance = uint256(ledger.balance).sub(scaledAmount);
        uint256 cost = uint256(ledger.cost).mul(nextBalance).div(ledger.balance);

        ledgers[_account] = Ledger(
            uint128(nextBalance),
            uint128(cost)
        );

        _totalSupply = cachedTotalSupply.sub(scaledAmount);
    }

    function _updateRewards(address _account, uint256 _cachedTotalSupply, bool _distribute, bool _updateLastBoughtAt) private {
        uint256 blockReward;
        Reward memory reward = rewards[_account];

        if (_distribute && distributor != address(0)) {
            blockReward = IX2Fund(distributor).distribute();
        }

        uint256 _cumulativeRewardPerToken = cumulativeRewardPerToken;
        // only update cumulativeRewardPerToken when there are stakers, i.e. when _totalSupply > 0
        // if blockReward == 0, then there will be no change to cumulativeRewardPerToken
        if (_cachedTotalSupply > 0 && blockReward > 0) {
            // PRECISION is 10^20 and the BASE_DIVISOR is 10^10
            // cachedTotalSupply = _totalSupply * divisor
            // the divisor will be around 10^10
            // if 1000 ETH worth is minted, then cachedTotalSupply = 1000 * 10^18 * 10^10 = 10^31
            // cumulativeRewardPerToken will increase by blockReward * 10^20 / (10^31)
            // if the blockReward is 0.001 REWARD_TOKENS
            // then cumulativeRewardPerToken will increase by 10^-3 * 10^18 * 10^20 / (10^31)
            // which is 10^35 / 10^31 or 10^4
            // if rewards are distributed every hour then at least 0.168 REWARD_TOKENS should be distributed per week
            // so that there will not be precision issues for distribution
            _cumulativeRewardPerToken = _cumulativeRewardPerToken.add(blockReward.mul(PRECISION).div(_cachedTotalSupply));
            cumulativeRewardPerToken = _cumulativeRewardPerToken;
        }

        // ledgers[_account].balance = balance * divisor
        // this divisor will be around 10^10
        // assuming that cumulativeRewardPerToken increases by at least 10^4
        // the claimableReward will increase by balance * 10^10 * 10^4 / 10^20
        // if the total supply is 1000 ETH
        // a user must own at least 10^-6 ETH or 0.000001 ETH worth of tokens to get some rewards
        uint256 claimableReward = uint256(reward.claimable).add(
            uint256(ledgers[_account].balance).mul(_cumulativeRewardPerToken.sub(reward.previousCumulativeRewardPerToken)).div(PRECISION)
        );

        if (claimableReward > MAX_REWARD) {
            claimableReward = MAX_REWARD;
        }

        if (_cumulativeRewardPerToken > MAX_CUMULATIVE_REWARD) {
            _cumulativeRewardPerToken = MAX_CUMULATIVE_REWARD;
        }

        rewards[_account] = Reward(
            // update previous cumulative reward for sender
            uint128(_cumulativeRewardPerToken),
            uint96(claimableReward),
            _updateLastBoughtAt ? uint32(block.timestamp % 2**32) : reward.lastBoughtAt
        );
    }
}
