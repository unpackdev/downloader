// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.12;

/**
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
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract CZVesting {
    address private _owner;
    uint256 private _startTime;
    uint256 private _unlockedAmount = 0;
    uint8 private _monthsLocked = 25;
    IERC20 private _token = IERC20(0x5A7060c5aDb519b4cb7A0ba2268F0697069F2717);

    receive() external payable {}

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }
    
    constructor() {
        _owner = msg.sender;
        _startTime = block.timestamp;
    }

    function unlock() external onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        require(balance > 0);

        uint256 passedSeconds = (block.timestamp - _startTime);
        uint256 passedMonths =  passedSeconds / 60 / 24 / 30;
        if (passedMonths > _monthsLocked) passedMonths = _monthsLocked;

        uint256 availableAmount = (balance + _unlockedAmount) * passedMonths / _monthsLocked;
        uint256 withdrawAmount = availableAmount - _unlockedAmount;

        _unlockedAmount += withdrawAmount;
        _token.transfer(_owner, withdrawAmount);
    }
}