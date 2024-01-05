pragma solidity >=0.6.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./FixedAmountVestingLibrary.sol";

contract FixedAmountVesting is ReentrancyGuard, Pausable, Ownable {
    
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    using FixedAmountVestingLibrary for FixedAmountVestingLibrary.Data;

    event Withdraw(address indexed sender, uint amount);
    event EmergencyWithdraw(address indexed owner, uint amount);

    struct LockupDetails {
        uint128 totalAmount;
        uint128 vestedPerInterval;
    }

    IERC20 immutable private token;

    FixedAmountVestingLibrary.Data private vestingData;
    mapping(address => LockupDetails) private _lockUpAmountOf;
    mapping(address => uint) public vestedAmountOf;

    constructor(
        address _token,
        uint32 _cliffEnd,
        uint32 _vestingInterval
    ) public {
        token = IERC20(_token);
        vestingData.initialize(
            _cliffEnd,
            _vestingInterval
        );

        _pause();
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setLockup(address[] calldata _accounts, uint128[] calldata _totalAmounts, uint128[] calldata _vestedPerInterval) external onlyOwner {
        require(_accounts.length == _totalAmounts.length && _totalAmounts.length == _vestedPerInterval.length, "FixedAmountVesting: LENGTH");
        for (uint i; i < _accounts.length; ++i) {
            // it's okay to set address as zero to reset the user-related data
            require(_vestedPerInterval[i] <= _totalAmounts[i], "FixedAmountVesting: MAX");
            _lockUpAmountOf[_accounts[i]] = LockupDetails({
                totalAmount: _totalAmounts[i],
                vestedPerInterval: _vestedPerInterval[i]
            });
        }
    }

    function emergencyWithdraw() external onlyOwner {
        uint balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(owner(), balance);
        emit EmergencyWithdraw(owner(), balance);
    }

    function withdraw() external whenNotPaused {
        LockupDetails storage lockup = _lockUpAmountOf[msg.sender];
        uint unlocked = vestingData.availableInputAmount(
            uint(lockup.totalAmount), 
            vestedAmountOf[msg.sender], 
            uint(lockup.vestedPerInterval), 
            uint(lockup.vestedPerInterval)
        );
        require(unlocked > 0, "Unlock: ZERO");
        vestedAmountOf[msg.sender] = vestedAmountOf[msg.sender].add(unlocked);
        IERC20(token).safeTransfer(msg.sender, unlocked);
        emit Withdraw(msg.sender, unlocked);
    }

    function lockUpAmountOf(address _account) external view returns (uint128 totalAmpount, uint128 vestedPerInterval) {
        LockupDetails storage lockup = _lockUpAmountOf[_account];
        totalAmpount = lockup.totalAmount;
        vestedPerInterval = lockup.vestedPerInterval;   
    }
 
    function unlockedAmountOf(address _account) external view returns (uint) {
        LockupDetails storage lockup = _lockUpAmountOf[_account];
        return vestingData.availableInputAmount(
            uint(lockup.totalAmount), 
            vestedAmountOf[_account], 
            uint(lockup.vestedPerInterval), 
            uint(lockup.vestedPerInterval)
        );
    }
}