pragma solidity >=0.6.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./FixedAmountVestingLibrary.sol";

contract FixedAmountVesting is ReentrancyGuard, Ownable {
    
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    using FixedAmountVestingLibrary for FixedAmountVestingLibrary.Data;

    event Withdraw(address indexed sender, uint amount);
    event SetLockup(address _account, uint128 total, uint128 vestedPerInterval);

    struct LockupDetails {
        uint128 totalAmount;
        uint128 vestedPerInterval;
    }

    mapping(address => uint) public vestedAmountOf;

    IERC20 immutable private token;
    FixedAmountVestingLibrary.Data private vestingData;
    mapping(address => LockupDetails) private _lockupAmountOf;

    constructor(
        address _token,
        uint64 _cliffEnd,
        uint32 _vestingInterval
    ) public {
        token = IERC20(_token);
        vestingData.initialize(
            _cliffEnd,
            _vestingInterval
        );
    }

    function setLockup(address[] calldata _accounts, uint128[] calldata _totalAmounts, uint128[] calldata _vestedPerInterval) external onlyOwner {
        require(_accounts.length == _totalAmounts.length && _totalAmounts.length == _vestedPerInterval.length, "FixedAmountVesting: LENGTH");
        for (uint i; i < _accounts.length; ++i) {
            require(_vestedPerInterval[i] <= _totalAmounts[i], "FixedAmountVesting: MAX");
            _lockupAmountOf[_accounts[i]] = LockupDetails({
                totalAmount: _totalAmounts[i],
                vestedPerInterval: _vestedPerInterval[i]
            });
            emit SetLockup(_accounts[i], _totalAmounts[i], _vestedPerInterval[i]);
        }
    }

    /// @notice Withdrawals are allowed only if ownership was renounced (setLockup cannot be called, vesting recipients cannot be changed anymore)
    function withdraw() external nonReentrant {
        require(owner() == address(0), "FixedAmountVesting: RENOUNCE_OWNERSHIP");
        LockupDetails storage lockup = _lockupAmountOf[msg.sender];
        uint unlocked = vestingData.availableInputAmount(
            uint(lockup.totalAmount), 
            vestedAmountOf[msg.sender], 
            uint(lockup.vestedPerInterval), 
            uint(lockup.vestedPerInterval)
        );
        require(unlocked > 0, "FixedAmountVesting: ZERO");
        vestedAmountOf[msg.sender] = vestedAmountOf[msg.sender].add(unlocked);
        IERC20(token).safeTransfer(msg.sender, unlocked);
        emit Withdraw(msg.sender, unlocked);
    }

    function lockupAmountOf(address _account) external view returns (uint128 totalAmpount, uint128 vestedPerInterval) {
        LockupDetails storage lockup = _lockupAmountOf[_account];
        totalAmpount = lockup.totalAmount;
        vestedPerInterval = lockup.vestedPerInterval;   
    }
 
    function unlockedAmountOf(address _account) external view returns (uint) {
        LockupDetails storage lockup = _lockupAmountOf[_account];
        return vestingData.availableInputAmount(
            uint(lockup.totalAmount), 
            vestedAmountOf[_account], 
            uint(lockup.vestedPerInterval), 
            uint(lockup.vestedPerInterval)
        );
    }
}