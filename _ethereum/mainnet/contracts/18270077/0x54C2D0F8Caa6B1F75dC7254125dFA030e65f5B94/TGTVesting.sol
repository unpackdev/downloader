// SPDX-License-Identifier: MPL

pragma solidity ~0.8.4;

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

interface ITGTERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract TGTVesting {
    ITGTERC20Metadata private _tgtContract;
    address private _owner;
    uint256 private _vestedBalance;
    uint64 public _startTimestamp;
    uint64 public _vestingDuration;

    mapping(address => VestingParams) private _vesting;

    struct VestingParams {
        //96bit are enough: max value is 1000000000000000000000000000
        //96bit are:                    79228162514264337593543950336
        uint96 vestingAmount;
        //64bit for timestamp in seconds lasts 584 billion years
        uint64 vestingDuration;
        //how much vested funds were already claimed
        uint96 vestingClaimed;
    }

    event Vested(address indexed account, uint96 amount, uint64 vestingDuration);
    event TransferOwner(address indexed owner);
    event SetStartTimestamp(uint64 startTimestamp);
    event Claim(address indexed account, uint96 amount);

    modifier onlyOwner(){
        require(msg.sender == _owner, "Vesting: not the owner");
        _;
    }

    constructor(address tgtContract, uint64 startTimestamp, uint64 vestingDuration) {
        _owner = msg.sender;
        _tgtContract = ITGTERC20Metadata(tgtContract);
        _startTimestamp = startTimestamp;
        _vestingDuration = vestingDuration;
    }

    function transferOwner(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Vesting: transfer owner the zero address");
        require(newOwner != address(this), "Vesting: transfer owner to this contract");

        _owner = newOwner;
        emit TransferOwner(newOwner);
    }

    function setStartTimestamp(uint64 startTimestamp) public virtual onlyOwner {
        require(block.timestamp < _startTimestamp, "Vesting: existing start timestamp has already been reached");
        require(block.timestamp < startTimestamp, "Vesting: can only set a start timestamp in the future");

        _startTimestamp = startTimestamp;
        emit SetStartTimestamp(startTimestamp);
    }

    function vest(address[] calldata accounts, uint96[] calldata amounts) public virtual onlyOwner {
        require(accounts.length == amounts.length, "Vesting: accounts and amounts length must match");

        for(uint256 i=0;i<accounts.length;i++) {
            //only vest those accounts that are not yet vested. We dont want to merge vestings
            if(_vesting[accounts[i]].vestingAmount == 0) {
                _vestedBalance += amounts[i];
                _vesting[accounts[i]] = VestingParams(amounts[i], _vestingDuration, 0);
                emit Vested(accounts[i], amounts[i], _vestingDuration);
            }
        }
        require(_vestedBalance <= _tgtContract.balanceOf(address(this)), "Vesting: not enough tokens in this contract for vesting");
    }

    function canClaim(address vested) public view virtual returns (uint256) {
        if(block.timestamp <= _startTimestamp || _startTimestamp == 0) {
            return 0;
        }
        VestingParams memory v = _vesting[vested];
        return claimableAmount(v);
    }

    function claimableAmount(VestingParams memory v) internal view virtual returns (uint256) {
        if (block.timestamp < _startTimestamp + v.vestingDuration) {
            return 0;
        }
        // Return the full vested amount minus what's already been claimed
        return v.vestingAmount - v.vestingClaimed;
    }

    function vestedBalance() public view virtual returns (uint256) {
        return _vestedBalance;
    }

    function vestedBalanceOf(address vested) public view virtual returns (uint256) {
        VestingParams memory v = _vesting[vested];
        return v.vestingAmount - v.vestingClaimed;
    }

    function claim(address to, uint96 amount) public virtual {
        require(block.timestamp > _startTimestamp, 'Vesting: timestamp now or in the past?');
        require(_startTimestamp != 0, "Vesting: contract not live yet");
        require(to != address(0), "Vesting: transfer from the zero address");
        require(to != address(this), "Vesting: sender is this contract");
        require(to != address(_tgtContract), "Vesting: sender is _tgtContract contract");

        VestingParams storage v = _vesting[msg.sender];

        require(amount <= claimableAmount(v), "TGT: cannot transfer vested funds");

        v.vestingClaimed += amount;
        _vestedBalance -= amount;
        _tgtContract.transfer(to, amount);
        emit Claim(to, amount);
    }
}