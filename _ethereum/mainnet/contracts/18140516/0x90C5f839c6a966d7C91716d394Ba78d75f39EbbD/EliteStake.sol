pragma solidity ^0.8.0;
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
pragma solidity ^0.8.0;
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
pragma solidity ^0.8.0;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
pragma solidity ^0.8.0;
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
pragma solidity ^0.8.0;
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}
pragma solidity ^0.8.9;
abstract contract StakeToken is Ownable {
    ERC20 public token;
    event TokenAddressUpdated(address oldAddress, address tokenAddress);
    function tokenName() public view returns (string memory) {
        return token.name();
    }
    function tokenSymbol() public view returns (string memory) {
        return token.symbol();
    }
    function tokenDecimals() public view returns (uint256) {
        return token.decimals();
    }
    function tokenBalanceOf(address _address) public view returns (uint256) {
        return token.balanceOf(_address);
    }
    function _changeTokenAddress(address newTokenAddress)
        internal
        onlyOwner
        returns (bool)
    {
        token = ERC20(newTokenAddress);
        require(newTokenAddress != address(0), "Token address cannot be 0");
        require(
            newTokenAddress != address(token),
            "Token address cannot be the same as the current one"
        );
        emit TokenAddressUpdated(address(token), newTokenAddress);
        return true;
    }
}
contract EliteStake is StakeToken {
    using SafeMath for uint256;
    event StakeMinAmountUpdated(uint256 amount);
    event StakeMaxAmountUpdated(uint256 amount);
    event StakePenaltyUpdated(uint256 stakePenalty);
    event TierListUpdated(uint256 level, uint256 percentage);
    event TierListTimeLimitUpdated(uint256 level, uint256 timeLimit);
    uint256 public minTxAmount = 0;
    uint256 public maxTxAmount = 0; 
    uint256 public penalty = 3;
    uint256 public totalRewardsDistributed = 0;
    uint256 public totalStaked = 0;
    bool public isStakingEnabled = false;
    bool private tokenWithdrawable = false;
    bool public useSpenderWallet = false;
    bool public singleTierOnly = false;
    address public spenderWallet;
    struct UserDetails {
        uint256 level;
        uint256 amount;
        uint256 initialTime;
        uint256 endTime;
        uint256 rewardAmount;
        uint256 withdrawAmount;
        bool isActive;
    }
    mapping(address => mapping(uint256 => UserDetails)) private user;
    mapping(uint256 => uint256) private tierList;
    mapping(address => uint256) public userTotalStakedAmount;
    mapping(uint256 => uint256) public tierListTimeLimit;
    mapping(uint256 => mapping(uint256 => uint256)) public advancedTierList;
    mapping(uint256 => uint256) public advancedTierListThresholds;
    bool public useAdvancedRewardCalculation = false;
    constructor(
        address _token,
        bool _withdrawable,
        uint256 _minTxAmount,
        uint256 _maxTxAmount,
        address _spenderWallet
    ) {
        token = ERC20(_token);
        tokenWithdrawable = _withdrawable;
        minTxAmount = _minTxAmount;
        maxTxAmount = _maxTxAmount;
        tierList[1] = 1; 
        tierList[2] = 1; 
        tierList[3] = 1; 
        tierList[4] = 1; 
        tierListTimeLimit[1] = 0; 
        tierListTimeLimit[2] = 30;
        tierListTimeLimit[3] = 60;
        tierListTimeLimit[4] = 90;
        if (_spenderWallet != address(0)) {
            useSpenderWallet = true;
            spenderWallet = _spenderWallet;
        }
    }
    modifier onlySpender() {
        require(
            msg.sender == spenderWallet,
            "Only spender wallet can call this function"
        );
        _;
    }
    function enableAdvancedRewardCalculation(
        uint256[3] memory _thresholds,
        uint256[3] memory _tierOnePercentages,
        uint256[3] memory _tierTwoPercentages,
        uint256[3] memory _tierThreePercentages,
        uint256[3] memory _tierFourPercentages
    ) external onlyOwner returns (bool) {
        uint256 decimals = token.decimals();
        advancedTierListThresholds[1] = _thresholds[0] * 10**decimals;
        advancedTierListThresholds[2] = _thresholds[1] * 10**decimals;
        advancedTierListThresholds[3] = _thresholds[2] * 10**decimals;
        advancedTierList[1][1] = _tierOnePercentages[0];
        advancedTierList[1][2] = _tierOnePercentages[1];
        advancedTierList[1][3] = _tierOnePercentages[2];
        advancedTierList[2][1] = _tierTwoPercentages[0];
        advancedTierList[2][2] = _tierTwoPercentages[1];
        advancedTierList[2][3] = _tierTwoPercentages[2];
        advancedTierList[3][1] = _tierThreePercentages[0];
        advancedTierList[3][2] = _tierThreePercentages[1];
        advancedTierList[3][3] = _tierThreePercentages[2];
        advancedTierList[4][1] = _tierFourPercentages[0];
        advancedTierList[4][2] = _tierFourPercentages[1];
        advancedTierList[4][3] = _tierFourPercentages[2];
        useAdvancedRewardCalculation = true;
        return true;
    }
    function disableAdvancedRewardCalculation()
        external
        onlyOwner
        returns (bool)
    {
        useAdvancedRewardCalculation = false;
        return true;
    }
    function getAdvancedRewards(uint256 _level) public view returns (uint256) {
        require(
            useAdvancedRewardCalculation,
            "Advanced reward calculation is not enabled"
        );
        uint256 _amount = user[msg.sender][_level].amount;
        uint256 thresholdLevel = 1;
        if (_amount < advancedTierListThresholds[1]) {
            thresholdLevel = 1;
        } else if (
            _amount >= advancedTierListThresholds[1] &&
            _amount < advancedTierListThresholds[2]
        ) {
            thresholdLevel = 2;
        } else {
            thresholdLevel = 3;
        }
        return advancedTierList[_level][thresholdLevel];
    }
    function changeSingleTierOnly(bool _singleTierOnly) external onlyOwner {
        singleTierOnly = _singleTierOnly;
    }
    function changeSpenderWallet(address _spenderWallet) external onlyOwner {
        useSpenderWallet = true;
        spenderWallet = _spenderWallet;
    }
    function retrieveToken(uint256 _amount) private {
        if (useSpenderWallet) {
            token.transferFrom(msg.sender, spenderWallet, _amount);
        } else {
            token.transferFrom(msg.sender, address(this), _amount);
        }
    }
    function sendToken(uint256 _amount) private {
        if (useSpenderWallet) {
            token.transferFrom(spenderWallet, msg.sender, _amount);
        } else {
            token.transfer(msg.sender, _amount);
        }
    }
    function changeTokenAddress(address newTokenAddress) external onlyOwner {
        require(
            !isStakingEnabled,
            "Cannot change token address while staking is enabled"
        );
        _changeTokenAddress(newTokenAddress);
    }
    function changeTierListTimeLimit(uint256 _level, uint256 _timeLimit)
        external
        onlyOwner
    {
        tierListTimeLimit[_level] = _timeLimit;
        emit TierListTimeLimitUpdated(_level, _timeLimit);
    }
    function changeMinTxAmount(uint256 _minTxAmount) external onlyOwner {
        minTxAmount = _minTxAmount;
        emit StakeMinAmountUpdated(minTxAmount);
    }
    function changeMaxTxAmount(uint256 _maxTxAmount) external onlyOwner {
        require(
            _maxTxAmount > minTxAmount,
            "Max amount must be greater than min amount"
        );
        maxTxAmount = _maxTxAmount;
        emit StakeMaxAmountUpdated(maxTxAmount);
    }
    function getTier(uint256 _level) external view returns (uint256) {
        return tierList[_level];
    }
    function getTiers() external view returns (uint256[3] memory) {
        return [tierList[1], tierList[2], tierList[3]];
    }
    function withdrawTokenFromContractJustInCase() external onlyOwner {
        require(!isStakingEnabled, "Staking should be disabled");
        require(tokenWithdrawable, "Token is not withdrawable");
        require(
            !useSpenderWallet,
            "You cannot withdraw token from spender wallet"
        );
        uint256 _amount = token.balanceOf(address(this));
        token.transfer(address(owner()), _amount);
    }
    function sendExactTokenFromContractToOwner(address _token, uint256 _amount)
        external
        onlyOwner
    {
        require(_token != address(0), "Token address cannot be null");
        ERC20 _tokenERC20 = ERC20(_token);
        require(
            _tokenERC20.balanceOf(address(this)) >= _amount,
            "Not enough token in contract"
        );
        _tokenERC20.transfer(address(owner()), _amount);
    }
    function changeTierList(uint256 _level, uint256 _percentage)
        external
        onlyOwner
        returns (bool)
    {
        require(tierList[_level] != 0, "Invalid level");
        tierList[_level] = _percentage;
        emit TierListUpdated(_level, _percentage);
        return true;
    }
    function disableStaking() external onlyOwner returns (bool) {
        isStakingEnabled = false;
        return true;
    }
    function enableStaking() external onlyOwner returns (bool) {
        isStakingEnabled = true;
        return true;
    }
    function stake(uint256 amount, uint256 level) external returns (bool) {
        require(isStakingEnabled, "Staking is disabled");
        if (singleTierOnly) {
            bool isBronzeActive = user[msg.sender][1].isActive;
            bool isSilverActive = user[msg.sender][2].isActive;
            bool isGoldActive = user[msg.sender][3].isActive;
            require(
                !isBronzeActive && !isSilverActive && !isGoldActive,
                "You can only stake once"
            );
        }
        uint256 tokenDecimals = token.decimals();
        uint256 _minTxAmount = minTxAmount * 10**tokenDecimals;
        require(amount >= _minTxAmount, "amount is less than minTxAmount");
        if (maxTxAmount > 0) {
            require(
                userTotalStakedAmount[msg.sender].add(amount) <=
                    maxTxAmount * 10**tokenDecimals,
                "You have exceeded your max amount"
            );
            require(
                amount <= maxTxAmount * 10**tokenDecimals,
                "amount is greater than maxTxAmount"
            );
        }
        require(!(user[msg.sender][level].isActive), "user already exist");
        retrieveToken(amount);
        setLevel(level);
        user[msg.sender][level].amount = amount;
        user[msg.sender][level].level = level;
        user[msg.sender][level].initialTime = block.timestamp;
        user[msg.sender][level].isActive = true;
        totalStaked = totalStaked.add(amount);
        userTotalStakedAmount[msg.sender] = userTotalStakedAmount[msg.sender]
            .add(amount);
        return true;
    }
    function setLevel(uint256 level) private {
        require(tierList[level] != 0, "Invalid level");
        if (level == 1) {
            user[msg.sender][level].endTime = 0;
        } else {
            user[msg.sender][level].endTime =
                block.timestamp +
                (tierListTimeLimit[level] * 1 days);
        }
    }
    function getRewards(address account, uint256 level)
        public
        view
        returns (uint256)
    {
        if (user[account][level].isActive) {
            uint256 stakeAmount = user[account][level].amount;
            uint256 timeDiff;
            require(
                block.timestamp >= user[account][level].initialTime,
                "Time exceeds"
            );
            unchecked {
                timeDiff = block.timestamp - user[account][level].initialTime;
            }
            uint256 rewardRate;
            if (useAdvancedRewardCalculation) {
                rewardRate = getAdvancedRewards(level);
            } else {
                rewardRate = tierList[level];
            }
            uint256 rewardAmount = (((stakeAmount * (rewardRate)) / 100) *
                timeDiff) / 365 days;
            return rewardAmount;
        } else return 0;
    }
    function withdraw(uint256 level) external returns (bool) {
        require(user[msg.sender][level].isActive, "user not exist");
        require(
            user[msg.sender][level].endTime <= block.timestamp,
            "staking end time is not reached"
        );
        uint256 rewardAmount = getRewards(msg.sender, level);
        uint256 amount = rewardAmount + user[msg.sender][level].amount;
        sendToken(amount);
        totalStaked = totalStaked.sub(user[msg.sender][level].amount);
        userTotalStakedAmount[msg.sender] = userTotalStakedAmount[msg.sender]
            .sub(user[msg.sender][level].amount);
        user[msg.sender][level].amount = 0;
        user[msg.sender][level].rewardAmount = user[msg.sender][level]
            .rewardAmount
            .add(rewardAmount);
        user[msg.sender][level].withdrawAmount += amount;
        user[msg.sender][level].isActive = false;
        totalRewardsDistributed = totalRewardsDistributed.add(rewardAmount);
        return true;
    }
    function changePenalty(uint256 _penalty) public onlyOwner {
        require(_penalty <= 50, "penalty should be less than 50");
        penalty = _penalty;
        emit StakePenaltyUpdated(_penalty);
    }
    function emergencyWithdraw(uint256 level) public returns (uint256) {
        require(user[msg.sender][level].isActive, "user not exist");
        uint256 _penalty;
        if (isStakingEnabled) {
            _penalty = penalty;
        } else {
            _penalty = 0;
        }
        uint256 stakedAmount = user[msg.sender][level].amount.sub(
            user[msg.sender][level].amount.mul(_penalty).div(100)
        );
        sendToken(stakedAmount);
        totalStaked = totalStaked.sub(user[msg.sender][level].amount);
        userTotalStakedAmount[msg.sender] = userTotalStakedAmount[msg.sender]
            .sub(user[msg.sender][level].amount);
        user[msg.sender][level].amount = 0;
        user[msg.sender][level].isActive = false;
        return stakedAmount;
    }
    function getUserDetails(address account, uint256 level)
        public
        view
        returns (UserDetails memory, uint256)
    {
        uint256 reward = getRewards(account, level);
        return (
            UserDetails(
                user[account][level].level,
                user[account][level].amount,
                user[account][level].initialTime,
                user[account][level].endTime,
                user[account][level].rewardAmount,
                user[account][level].withdrawAmount,
                user[account][level].isActive
            ),
            reward
        );
    }
}