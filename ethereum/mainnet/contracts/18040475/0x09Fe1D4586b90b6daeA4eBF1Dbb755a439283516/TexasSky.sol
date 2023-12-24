// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}


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

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
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
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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


contract Freezable {
    mapping(address => bool) private _freezes;

    event Freezed(address indexed account);
    event Unfreezed(address indexed account);

    /**
     * @dev Freeze account, only owner can freeze
     */
    function _freeze(address account) internal {
        _freezes[account] = true;
        emit Freezed(account);
    }

    /**
     * @dev Unfreeze account, only supervisor can unfreeze
     */
    function _unfreeze(address account) internal {
        _freezes[account] = false;
        emit Unfreezed(account);
    }

    /**
     * @dev Returns whether the address is freezed.
     */
    function isFreezed(address account) public view returns (bool) {
        return _freezes[account];
    }
}


contract Lockable {
    struct TimeLock {
        uint256 amount;
        uint256 lockedAt;
        uint256 expiresAt;
    }

    struct VestingLock {
        uint256 amount;
        uint256 lockedAt;
        uint256 startsAt;
        uint256 period;
        uint256 count;
    }

    mapping(address => TimeLock[]) private _timeLocks;
    mapping(address => VestingLock[]) private _vestingLocks;

    event TimeLocked(address indexed account);
    event TimeUnlocked(address indexed account);
    event VestingLocked(address indexed account);
    event VestingUnlocked(address indexed account);
    event VestingUpdated(address indexed account, uint256 index);


    function _addTimeLock(
        address account,
        uint256 amount,
        uint256 expiresAt
    ) internal {
        require(amount > 0, "TimeLock: lock amount is 0");
        require(expiresAt > block.timestamp, "TimeLock: invalid expire date");
        _timeLocks[account].push(TimeLock(amount, block.timestamp, expiresAt));
        emit TimeLocked(account);
    }

    /**
     * @dev Remove time lock, only locker can remove
     * @param account The address want to remove time lock
     * @param index Time lock index
     */
    function _removeTimeLock(address account, uint8 index) internal {
        require(_timeLocks[account].length > index && index >= 0, "TimeLock: invalid index");

        uint256 len = _timeLocks[account].length;
        if (len - 1 != index) {
            // if it is not last item, swap it
            _timeLocks[account][index] = _timeLocks[account][len - 1];
        }
        _timeLocks[account].pop();
        emit TimeUnlocked(account);
    }

    /**
     * @dev Get time lock array length
     * @param account The address want to know the time lock length.
     * @return time lock length
     */
    function getTimeLockLength(address account) public view returns (uint256) {
        return _timeLocks[account].length;
    }

    /**
     * @dev Get time lock info
     * @param account The address want to know the time lock state.
     * @param index Time lock index
     * @return time lock info
     */
    function getTimeLock(address account, uint8 index) public view returns (uint256, uint256) {
        require(_timeLocks[account].length > index && index >= 0, "TimeLock: invalid index");
        return (_timeLocks[account][index].amount, _timeLocks[account][index].expiresAt);
    }

    function getAllTimeLocks(address account) public view returns (TimeLock[] memory) {
        require(account != address(0), "TimeLock: query for the zero address");
        return _timeLocks[account];
    }

    /**
     * @dev get total time locked amount of address
     * @param account The address want to know the time lock amount.
     * @return time locked amount
     */
    function getTimeLockedAmount(address account) public view returns (uint256) {
        uint256 timeLockedAmount = 0;

        uint256 len = _timeLocks[account].length;
        for (uint256 i = 0; i < len; i++) {
            if (block.timestamp < _timeLocks[account][i].expiresAt) {
                timeLockedAmount = timeLockedAmount + _timeLocks[account][i].amount;
            }
        }
        return timeLockedAmount;
    }

    /**
     * @dev Add vesting lock, only locker can add
     * @param account vesting lock account.
     * @param amount vesting lock amount.
     * @param startsAt vesting lock release start date.
     * @param period vesting lock period. End date is startsAt + (period - 1) * count
     * @param count vesting lock count. If count is 1, it works like a time lock
     */
    function _addVestingLock(
        address account,
        uint256 amount,
        uint256 startsAt,
        uint256 period,
        uint256 count
    ) internal {
        require(account != address(0), "VestingLock: lock from the zero address");
        // require(startsAt > block.timestamp, "VestingLock: must set after now");
        require(period > 0, "VestingLock: period is 0");
        require(count > 0, "VestingLock: count is 0");
        _vestingLocks[account].push(VestingLock(amount, block.timestamp, startsAt, period, count));
        emit VestingLocked(account);
    }

    /**
     * @dev Remove vesting lock, only supervisor can remove
     * @param account The address want to remove the vesting lock
     */
    function _removeVestingLock(address account, uint256 index) internal {
        require(index < _vestingLocks[account].length, "Invalid index");

        if (index != _vestingLocks[account].length - 1) {
            _vestingLocks[account][index] = _vestingLocks[account][_vestingLocks[account].length - 1];
        }
        _vestingLocks[account].pop();
    }

    function _updateVestingLock(
        address account,
        uint256 index,
        uint256 amount,
        uint256 startsAt,
        uint256 period,
        uint256 count
    ) internal {
        require(account != address(0), "VestingLock: lock from the zero address");
        // require(startsAt > block.timestamp, "VestingLock: must set after now");
        require(amount > 0, "VestingLock: amount is 0");
        require(period > 0, "VestingLock: period is 0");
        require(count > 0, "VestingLock: count is 0");

        VestingLock storage lock = _vestingLocks[account][index];
        lock.amount = amount;
        lock.startsAt = startsAt;
        lock.period = period;
        lock.count = count;

        emit VestingUpdated(account, index);
    }

    /**
     * @dev Get vesting lock info
     * @param account The address want to know the vesting lock state.
     * @return vesting lock info
     */
    function getVestingLock(address account, uint256 index) public view returns (VestingLock memory) {
        return _vestingLocks[account][index];
    }

    /**
     * @dev Get total vesting locked amount of address, locked amount will be released by 100%/months
     * If months is 5, locked amount released 20% per 1 month.
     * @param account The address want to know the vesting lock amount.
     * @return vesting locked amount
     */
    function getVestingLockedAmount(address account) public view returns (uint256) {
        uint256 vestingLockedAmount = 0;
        for (uint256 i = 0; i < _vestingLocks[account].length; i++) {
          VestingLock memory lock = _vestingLocks[account][i];
          
          uint256 amount = lock.amount;
          if (amount > 0) {
              uint256 startsAt = lock.startsAt;
              uint256 period = lock.period;
              uint256 count = lock.count;
              uint256 expiresAt = startsAt + period * (count);
              uint256 timestamp = block.timestamp;
              if (timestamp < startsAt) {
                  vestingLockedAmount += amount;
              } else if (timestamp < expiresAt) {
                  vestingLockedAmount += (amount * ((expiresAt - timestamp) / period)) / count;
              }
          }
        }
        return vestingLockedAmount;
    }

    /**
     * @dev Get all locked amount
     * @param account The address want to know the all locked amount
     * @return all locked amount
     */
    function getAllLockedAmount(address account) public view returns (uint256) {
        return getTimeLockedAmount(account) + getVestingLockedAmount(account);
    }

    function getAllVestingCount(address account) public view returns (uint256) {
        require(account != address(0), "VestingLock: query for the zero address");
        return _vestingLocks[account].length;
    }

    function getAllVestings(address account) public view returns (VestingLock[] memory) {
        require(account != address(0), "VestingLock: query for the zero address");
        return _vestingLocks[account];
    }
           
    function Checktimelock(address account) public returns (bool) {
        for (uint8 i = 0; i < _timeLocks[account].length; i++) {
            if (_timeLocks[account][i].expiresAt < block.timestamp) {
                _removeTimeLock(account, i);
            }
        }
        return true;
    }

}

abstract contract ERC20Burnable is Context, ERC20 {

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }
}

contract TexasSky is ERC20, Ownable, Freezable, Lockable, ERC20Burnable {

    constructor() ERC20("Texas Sky", "TXO") {
        _mint(msg.sender, 2000000000 * (10 ** decimals()));
    }

    function maxSupply() public view returns (uint256) {
        return 20000000000 * (10 ** decimals());
    }

    function freeze(address account) public onlyOwner {
        _freeze(account);
    }

    function unfreeze(address account) public onlyOwner {
        _unfreeze(account);
    }


    function addTimeLock(address account, uint256 amount, uint256 expiresAt) public onlyOwner  {
        _addTimeLock(account, amount, expiresAt);
    }

    function removeTimeLock(address account, uint8 index) public onlyOwner {
        _removeTimeLock(account, index);
    }

    function addVestingLock(
        address account,
        uint256 amount,
        uint256 startsAt,
        uint256 period,
        uint256 count
    ) public onlyOwner {
        require(amount > 0 && balanceOf(account) >= amount, "VestingLock: amount is 0 or over balance");
        _addVestingLock(account, amount, startsAt, period, count);
    }

    function updateVestingLock(
        address account,
        uint256 index,
        uint256 amount,
        uint256 startsAt,
        uint256 period,
        uint256 count
    ) public onlyOwner {
        _updateVestingLock(account, index, amount, startsAt, period, count);
    }

    function removeVestingLock(address account, uint index) public onlyOwner {
        _removeVestingLock(account, index);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override (ERC20) {
        require(!isFreezed(from), "Freezable: token transfer from freezed account");
        require(!isFreezed(to), "Freezable: token transfer to freezed account");
        require(!isFreezed(_msgSender()), "Freezable: token transfer called from freezed account");
        if (from != address(0)) require(balanceOf(from) - getAllLockedAmount(from) >= amount, "Lockable: insufficient transfer amount");

        super._beforeTokenTransfer(from, to, amount);
    }

    function batchTransfer(address[] memory recipients, uint256[] memory amounts) public {
        require(recipients.length == amounts.length, "EML: recipients and amounts length mismatch");

        for (uint256 i = 0; i < recipients.length; i++) {
            transfer(recipients[i], amounts[i]);
        }
    }

    function vestedTransfer(
        address recipient,
        uint256 amount,
        uint256 startsAt,
        uint256 period,
        uint256 count
    ) public onlyOwner {
        // Transfer tokens to the recipient
        transfer(recipient, amount);

        // Add a vesting lock for the recipient
        addVestingLock(recipient, amount, startsAt, period, count);
    }

    function lockedTransfer(
        address recipient,
        uint256 amount,
        uint256 expiresAt
    ) public onlyOwner {
        // Transfer tokens to the recipient
        transfer(recipient, amount);

        // Add a timed lock for the recipient
        addTimeLock(recipient, amount, expiresAt);
    }

    function batchVestedTransfer(
        address[] memory recipients,
        uint256[] memory amounts,
        uint256[] memory startsAt,
        uint256[] memory periods,
        uint256[] memory counts
    ) public onlyOwner {
        require(
            recipients.length == amounts.length &&
            ((recipients.length == startsAt.length && recipients.length == periods.length && recipients.length == counts.length) || 
            (startsAt.length == 1 && periods.length == 1 && counts.length == 1)),
            "EML: arrays must have the same length"
        );

        if (startsAt.length == 1 && periods.length == 1 && counts.length == 1) {
            for (uint256 i = 0; i < recipients.length; i++) {
                // Transfer tokens to the recipient
                transfer(recipients[i], amounts[i]);
                addVestingLock(
                    recipients[i],
                    amounts[i],
                    startsAt[0],
                    periods[0],
                    counts[0]
                );
            }
        } else {
            for (uint256 i = 0; i < recipients.length; i++) {
                // Transfer tokens to the recipient
                transfer(recipients[i], amounts[i]);
                addVestingLock(
                    recipients[i],
                    amounts[i],
                    startsAt[i],
                    periods[i],
                    counts[i]
                );
            }
        }
    }

    function batchTimeLockedTransfer(address[] memory recipients, uint256[] memory amounts,uint256[] memory expiresAt) public onlyOwner {
        require(
            recipients.length == amounts.length &&
            ((recipients.length == expiresAt.length) || (expiresAt.length == 1)),
            "EML: arrays must have the same length"
        );

        if (expiresAt.length == 1) {
            for (uint256 i = 0; i < recipients.length; i++) {
                // Transfer tokens to the recipient
                transfer(recipients[i], amounts[i]);
                addTimeLock(
                    recipients[i],
                    amounts[i],
                    expiresAt[0]
                );
            }
        } else {
            for (uint256 i = 0; i < recipients.length; i++) {
                // Transfer tokens to the recipient
                transfer(recipients[i], amounts[i]);
                addTimeLock(
                    recipients[i],
                    amounts[i],
                    expiresAt[i]
                );
            }
        }
    }

}