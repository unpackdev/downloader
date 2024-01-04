pragma solidity >=0.6.0 <0.7.0;

import "./BarnInterface.sol";
import "./BarnRewardsInterface.sol";
import "./ERC20Mintable.sol";
import "./FixedPoint.sol";
import "./IERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";

contract BarnBridgeToken is
    ERC20Mintable("BarnBridge Governance Token", "BOND")
{}

contract BarnFacetMock is BarnInterface {
    using SafeMathUpgradeable for uint256;

    uint256 public constant MAX_LOCK = 365 days;
    uint256 constant BASE_MULTIPLIER = 1e18;

    BarnBridgeToken public bond;
    BarnRewardsInterface public rewards;

    uint256 public override bondStaked;
    mapping(address => uint256) private balances;
    mapping(address => uint256) private lockedBalances;

    event Deposit(address indexed user, uint256 amount, uint256 newBalance);
    event Withdraw(
        address indexed user,
        uint256 amountWithdrew,
        uint256 amountLeft
    );
    event Lock(address indexed user, uint256 timestamp);

    constructor() public {}

    function initBarn(address _bond, address _rewards) public {
        bond = BarnBridgeToken(_bond);
        rewards = BarnRewardsInterface(_rewards);
    }

    function balance() public view returns (uint256) {
        return bond.balanceOf(address(this));
    }

    function deposit(uint256 _amount) public override {
        address user = msg.sender;
        uint256 allowance = bond.allowance(msg.sender, address(this));

        require(_amount > 0, "Amount must be greater than 0");
        require(allowance >= _amount, "Token allowance too small");

        uint256 newBalance = balanceOf(user).add(_amount);
        _updateUserBalance(user, newBalance);

        bondStaked = bondStaked.add(_amount);
        bond.transferFrom(user, address(this), _amount);
        callRegisterUserAction(user);
        emit Deposit(msg.sender, _amount, newBalance);
    }

    function lock(uint256 timestamp) public {
        _lock(msg.sender, timestamp);
        emit Lock(msg.sender, timestamp);
    }

    function depositAndLock(uint256 amount, uint256 timestamp) public override {
        deposit(amount);
        lock(timestamp);
    }

    function _lock(address user, uint256 timestamp) internal {
        require(timestamp > block.timestamp, "Timestamp must be in the future");
        require(timestamp <= block.timestamp + MAX_LOCK, "Timestamp too big");
        require(balanceOf(user) > 0, "Sender has no balance");

        _updateUserLock(user, timestamp);
    }

    function withdraw(uint256 amount) public override {
        address user = msg.sender;
        require(amount > 0, "Amount must be greater than 0");
        require(
            userLockedUntil(msg.sender) <= block.timestamp,
            "User balance is locked"
        );

        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        uint256 balanceAfterWithdrawal = balanceOf(msg.sender).sub(amount);
        _updateUserBalance(user, balanceAfterWithdrawal);

        bondStaked = bondStaked.sub(amount);
        bond.transfer(msg.sender, amount);
        callRegisterUserAction(user);
        emit Withdraw(msg.sender, amount, balanceAfterWithdrawal);
    }

    function callRegisterUserAction(address user) public {
      rewards.registerUserAction(user);
    }

    function balanceOf(address user) public view override returns (uint256) {
        return balances[user];
    }

    function _updateUserBalance(address user, uint256 amount) internal {
        balances[user] = amount;
    }

    function _updateLockedBond(uint256 amount) internal {}

    function _updateUserLock(address user, uint256 timestamp) internal {
        lockedBalances[user] = timestamp;
    }

    function userLockedUntil(address user)
        public
        view
        override
        returns (uint256)
    {
        return lockedBalances[user];
    }

}
