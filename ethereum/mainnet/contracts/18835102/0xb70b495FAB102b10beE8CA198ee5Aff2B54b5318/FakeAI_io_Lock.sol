pragma solidity 0.8.19;

/*
 *
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract FakeAI_io_Lock {
    uint256 public timer;
    uint256 public totalLocked;
    address immutable owner;

    IERC20 private lockedToken;
    
    struct Locker {
        uint256 amount;
        uint256 endTime;
    }

    mapping(address => Locker) lockInfo;


    event Locked(address indexed sender, uint256 lockedAmount);
    event Unlocked(address indexed sender, uint256 lockedAmount);
    event Timer(uint256 oldtime, uint256 newtime);
    event TokenAddress(address indexed oldAddress, address indexed newAddress);

    constructor(address initialOwner, address _lockedToken)
    {
        require(_lockedToken != address(0), "Zero Address Not Allowed");
        require(initialOwner != address(0), "Zero Address Not Allowed");

        owner = initialOwner;
        lockedToken = IERC20(_lockedToken);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Not the Owner");
        _;
    }

    function lock(uint256 _amount) external {
        if (_amount == 0) revert("Can't stake zero tokens");

        lockedToken.transferFrom(msg.sender, address(this), _amount);

        totalLocked += _amount;
        lockInfo[msg.sender].amount += _amount;
        lockInfo[msg.sender].endTime = block.timestamp + timer;

        emit Locked(msg.sender, _amount);
    }

    function unlock(uint256 _amount) external {
        if (_amount == 0) revert("Can't unstake zero tokens");

        uint256 endTime = lockInfo[msg.sender].endTime;

        if (block.timestamp < endTime) revert("Staking period still active");

        uint256 balance = lockInfo[msg.sender].amount;

        if (balance < _amount) revert("Insufficient Balance");

        totalLocked -= _amount;
        lockInfo[msg.sender].amount -= _amount;
        lockInfo[msg.sender].endTime = 0;

        lockedToken.transfer(msg.sender, _amount);

        emit Unlocked(msg.sender, _amount);
    }

    function setLockPeriod(uint256 _time) external onlyOwner {
        uint256 oldtime = timer;
        timer = _time;
        emit Timer(oldtime, _time);
    }

    function changeTokenAddress(address _token) external onlyOwner {
        if (_token == address(0)) revert("Zero Address not allowed");

        IERC20 oldtoken = lockedToken;
        lockedToken = IERC20(_token);

        emit TokenAddress(address(oldtoken), _token);
    }

    function lockerInfo(address locker)
        public
        view
        returns (uint256 amount, uint256 timeLeft)
    {
        amount = lockInfo[locker].amount;
        uint256 endTime = lockInfo[locker].endTime;
        if (block.timestamp <= endTime) {
            timeLeft = endTime - block.timestamp;
        } else {
            timeLeft;
        }
    }
}