pragma solidity ^0.5.16;

import "./Math.sol";
import "./SafeMath.sol";
import "./ERC20Detailed.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

contract ArchiLockUp is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public lockToken;
    uint256 public periodFinish;
    uint256 public constant DELAY_DURATION = 86400;
    address private _owner;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(address _lockToken, uint256 _lockDuration) public {
        _owner = msg.sender;
        lockToken = IERC20(_lockToken);
        periodFinish = block.timestamp.add(_lockDuration);
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lock(uint256 amount) external nonReentrant {
        require(amount > 0, "LOCK_AMOUNT_ZERO");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        lockToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Locked(msg.sender, amount);
    }

    function unlock(uint256 amount) external nonReentrant {
        require(periodFinish < block.timestamp, "LOCKUP_PERIOD_NOT_FINISH");
        require(amount > 0, "UNLOCK_AMOUNT_ZERO");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        lockToken.safeTransfer(msg.sender, amount);
        emit UnLocked(msg.sender, amount);
    }

    function resetLockUpPeriod(uint256 _lockDuration) external onlyOwner{
        require(periodFinish + DELAY_DURATION < block.timestamp, "NOT_ALLOWED_RESET");
        periodFinish = block.timestamp.add(_lockDuration);
        emit LockUpPeriodReset(block.timestamp, _lockDuration);
    }

    event Locked(address indexed user, uint256 amount);
    event UnLocked(address indexed user, uint256 amount);
    event LockUpPeriodReset(uint256 blockTimestamp, uint256 lockDuration);

    modifier onlyOwner {
        require(msg.sender == _owner, "ONLY_OWNER");
        _;
    }
}