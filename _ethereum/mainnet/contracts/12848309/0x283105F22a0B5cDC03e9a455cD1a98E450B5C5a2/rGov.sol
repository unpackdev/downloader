pragma solidity 0.8.5;
import "./ERC20.sol";
import "./Ownable.sol";

contract rGov is ERC20, Ownable {
    address public IterationSyndicate;
    uint256 public rate;
    uint256 public lock_duration;
    mapping( address => uint256 ) public locks;

    constructor(
        address IterationSyndicate_,
        uint256 rate_,
        uint256 lock_duration_
    ) ERC20('rGov', 'rGov') {
        IterationSyndicate = IterationSyndicate_;
        rate = rate_;
        lock_duration = lock_duration_;
    }

    function mint(uint256 stake_) external {
        IERC20(IterationSyndicate).transferFrom(msg.sender, address(this), stake_);
        locks[msg.sender] = block.timestamp + lock_duration;
        _mint(msg.sender, stake_ * rate);
    }

    function burn(uint256 amount_) external {
        require(locks[msg.sender] < block.timestamp, "Too soon");
        require(amount_ > rate, "Fuel required to burn");
        locks[msg.sender] = block.timestamp + lock_duration;
        _burn(msg.sender, amount_);
        IERC20(IterationSyndicate).transfer(msg.sender, amount_ / rate);
    }
    // Don't
    function transfer(
        address recipient, 
        uint256 amount
    ) public virtual override returns (bool) {
        assert(false);
        return false;
    }
    // Do
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        assert(false);
        return false;
    }
    // This
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        assert(false);
        return false;
    }    

    function setLockDuration(
        uint256 lock_duration_
    ) external onlyOwner {
        require(lock_duration < 3 days);
        lock_duration = lock_duration_;
    }
}