pragma solidity ^0.8.17;

import "./Erc20.sol";
import "./Erc20.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract Touch is ERC20 {
    uint256 public constant rewardPercentMin = 10; // 1 %
    uint256 public constant rewardPercentMax = 200; // 20%
    uint256 public constant rewardInterwal = 180 seconds;
    uint256 public constant startTotalSupply = 1e9 * (10 ** _decimals);
    uint256 constant _startMaxBuyCount = startTotalSupply / 1000;
    uint256 constant _addMaxBuyPercentPerSec = 5; // add 0.005%/second
    IUniswapV2Router02 constant router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    bool _inSwap;
    address pair;
    uint256 _startTime;
    bool public canReward;
    uint256 public rewardVersion; // reward version
    uint256 public rewardedCurrentVersion; // rewarded on current version
    uint256 public rewards; // current rewards
    uint256 public nextRewardTime;
    uint256 public tokensOnAccounts; // tokens on all accounts
    uint256 public tokensOnAccountsCurrentVerstion;
    address public owner;
    uint256 _nonce = 1;
    mapping(address => uint256) _rewardVersionsByAccs;

    event OnReward(uint256 count);

    constructor() ERC20("touch", "grass") {
        owner = msg.sender;
    }

    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        _updateReward(from);
        _updateReward(to);

        if (_inSwap) {
            super._transfer(from, to, amount);
            return;
        }

        if (to == address(0)) {
            require(
                _balances[from] >= amount,
                "ERC20: transfer amount exceeds balance"
            );
            unchecked {
                _balances[from] -= amount;
                _totalSupply -= amount;
            }
            emit Transfer(from, to, amount);
            return;
        }

        if (from == pair) {
            transferFromPair(to, amount);
            return;
        }

        if (to == pair) {
            transferToPair(from, amount);
            return;
        }

        super._transfer(from, to, amount);
    }

    function transferFromPair(address to, uint256 amount) private {
        require(amount <= maxBuy(), "maximum buy count limit");
        uint256 burnCount = (amount * 25) / 10000;
        _burn(pair, burnCount);
        uint256 toAccCount = amount - burnCount;
        super._transfer(pair, to, toAccCount);
        if (_isAccount(to)) {
            tokensOnAccounts += toAccCount;
        }
    }

    function transferToPair(address from, uint256 amount) private {
        uint256 burnCount = (amount * 25) / 10000;
        _burn(from, burnCount);
        super._transfer(from, pair, amount - burnCount);
        if (_isAccount(from)) {
            tokensOnAccounts -= amount;
        }
    }

    function burned() public view returns (uint256) {
        return startTotalSupply - totalSupply();
    }

    function makePool() external payable lockTheSwap {
        pair = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            router.WETH()
        );
        _mint(address(this), startTotalSupply);
        _approve(address(this), address(router), type(uint256).max);
        router.addLiquidityETH{value: msg.value}(
            address(this),
            startTotalSupply / 2,
            0,
            0,
            msg.sender,
            block.timestamp
        );
        _startTime = block.timestamp;
    }

    function maxBuy() public view returns (uint256) {
        if (pair == address(0)) return startTotalSupply;
        uint256 count = _startMaxBuyCount +
            (startTotalSupply *
                (block.timestamp - _startTime) *
                _addMaxBuyPercentPerSec) /
            100000;
        if (count > startTotalSupply) count = startTotalSupply;
        return count;
    }

    function maxBuyWithoutDecimals() public view returns (uint256) {
        return maxBuy() / (10 ** _decimals);
    }

    function _rand() private returns (uint256) {
        return _nonce++ * block.timestamp * block.number;
    }

    function _rand(uint256 min, uint256 max) private returns (uint256) {
        return min + (_rand() % (max - min + 1));
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        if (account == address(this)) return _balances[account] - rewards;
        return _balances[account] + getReward(account);
    }

    function getReward(address account) public view returns (uint256) {
        if (tokensOnAccountsCurrentVerstion == 0) return 0;
        if (!_isAccount(account)) return 0;
        if (rewardVersion == 0) return 0;
        if (_rewardVersionsByAccs[account] == rewardVersion) return 0;
        return
            (rewardedCurrentVersion * _balances[account]) /
            tokensOnAccountsCurrentVerstion;
    }

    function updateReward(address account) external {
        // updates account reward (for emit events)
        _updateReward(account);
    }

    function _updateReward(address account) private {
        uint256 reward = getReward(account);
        _rewardVersionsByAccs[account] = rewardVersion;
        if (reward == 0) return;

        rewards -= reward;
        _balances[address(this)] -= reward;
        _balances[account] += reward;
        tokensOnAccounts += reward;
        emit Transfer(address(this), account, reward);
    }

    function _isAccount(address addr) private view returns (bool) {
        return addr != address(0) && addr != pair && addr != address(this);
    }

    function touchGrass() external {
        require(block.timestamp >= nextRewardTime, "can not grant rewards yet");
        nextRewardTime = block.timestamp + rewardInterwal;
        uint256 addRewards = (balanceOf(address(this)) *
            _rand(rewardPercentMin, rewardPercentMax)) / 1000;
        _grantRewards(addRewards);
    }

    function _grantRewards(uint256 count) internal {
        require(canReward, "can not reward yet");
        rewards += count;
        rewardedCurrentVersion = rewards;
        tokensOnAccountsCurrentVerstion = tokensOnAccounts;
        ++rewardVersion;
        emit OnReward(count);
    }

    function startProtocolAndRenounce() external {
        require(msg.sender == owner, "only owner");
        owner = address(0);
        canReward = true;
    }
}
