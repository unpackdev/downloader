// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC20Burnable.sol";
import "./SafeERC20.sol";
import "./Context.sol";

contract LeisureMeta is ERC20Burnable, Ownable, Pausable {
    LeisureMetaTimeLock public immutable daoPoolLock;
    uint256 private _dDay;

    event SetDDay(uint256 dDay);
    event SalesLock(
        address lock,
        address indexed beneficiary,
        uint256 totalAmount
    );
    event GeneralLock(
        address lock,
        address indexed beneficiary,
        uint256 totalAmount
    );

    constructor(address daopool, uint256 initialDDay)
        ERC20("LeisureMeta", "LM")
    {
        uint256 totalAmount = 5_000_000_000 * (10**uint256(decimals()));
        uint256 sixtyPercent = (totalAmount * 60) / 100;
        uint256 fortyPercent = (totalAmount * 40) / 100;

        _dDay = initialDDay;

        daoPoolLock = daoLock(daopool, sixtyPercent);
        _mint(_msgSender(), fortyPercent);
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }

    /**
     * @dev Set D-Day which might be the first day of listing in major crypto exchanges.
     */
    function setDDay(uint256 dDay) external onlyOwner {
        require(dDay > block.timestamp, "D-Day must be in the future");
        _dDay = dDay;
        emit SetDDay(_dDay);
    }

    function getDDay() external view returns (uint256) {
        return _dDay;
    }

    function daoLock(address beneficiary, uint256 amount)
        internal
        onlyOwner
        returns (LeisureMetaTimeLock)
    {
        uint256 aDay = 24 * 3600;
        uint256[] memory amounts = new uint256[](60);
        uint256[] memory releaseTimes = new uint256[](60);
        for (uint256 i = 0; i < 60; i++) {
            amounts[i] = amount / 60;
            releaseTimes[i] = 30 * aDay * (60 - i - 1);
        }

        LeisureMetaTimeLock lock = new LeisureMetaTimeLock(
            this,
            beneficiary,
            amounts,
            releaseTimes,
            false
        );
        _mint(address(lock), amount);
        return lock;
    }

    function saleLock(address beneficiary, uint256 amount)
        external
        onlyOwner
        returns (LeisureMetaTimeLock)
    {
        uint256 aDay = 24 * 3600;
        uint256[] memory amounts = new uint256[](12);
        uint256[] memory releaseTimes = new uint256[](12);
        for (uint256 i = 0; i < 10; i++) {
            amounts[i] = amount / 10;
            releaseTimes[i] = 30 * aDay * (11 - i);
        }
        amounts[10] = (amount * 9) / 100;
        releaseTimes[10] = 30 * aDay;
        amounts[11] = amount / 100;
        releaseTimes[11] = 0;
        LeisureMetaTimeLock lock = _lock(
            beneficiary,
            amounts,
            releaseTimes,
            false
        );
        emit SalesLock(address(lock), beneficiary, amount);
        return lock;
    }

    function generalLock(address beneficiary, uint256 amount)
        external
        onlyOwner
        returns (LeisureMetaTimeLock)
    {
        uint256 aDay = 24 * 3600;
        uint256[] memory amounts = new uint256[](20);
        uint256[] memory releaseTimes = new uint256[](20);
        for (uint256 i = 0; i < 20; i++) {
            amounts[i] = amount / 20;
            releaseTimes[i] = 30 * aDay * (25 - i);
        }
        LeisureMetaTimeLock lock = _lock(
            beneficiary,
            amounts,
            releaseTimes,
            true
        );
        emit GeneralLock(address(lock), beneficiary, amount);
        return lock;
    }

    function _lock(
        address beneficiary_,
        uint256[] memory amounts_,
        uint256[] memory releaseTimes_,
        bool revocable_
    ) internal onlyOwner returns (LeisureMetaTimeLock) {
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts_.length; i++) {
            totalAmount += amounts_[i];
        }
        require(totalAmount <= balanceOf(_msgSender()), "insufficient balance");

        LeisureMetaTimeLock item = new LeisureMetaTimeLock(
            this,
            beneficiary_,
            amounts_,
            releaseTimes_,
            revocable_
        );
        transfer(address(item), totalAmount);
        return item;
    }
}

contract LeisureMetaTimeLock is Context {
    using SafeERC20 for LeisureMeta;
    LeisureMeta public immutable LM;

    address public immutable beneficiary;
    bool public immutable revocable;

    uint256[] private _lockedAmounts;
    uint256[] private _releaseTimes;

    event Release(
        address indexed beneficiary,
        uint256 amount,
        uint256 releaseTime
    );
    event Revoke(address indexed from, uint256 amount, uint256 revokeTime);

    /**
     * @dev Deploys a timelock instance that is able to hold the token specified, and will only release it to
     * `beneficiary_` when {release} is invoked after D-Day + `releaseTime_` (seconds).
     */
    constructor(
        LeisureMeta lm_,
        address beneficiary_,
        uint256[] memory lockedAmounts_,
        uint256[] memory releaseTimes_,
        bool revocable_
    ) {
        require(
            lockedAmounts_.length == releaseTimes_.length,
            "lockedAmounts and releaseTimes must be of the same length"
        );
        require(beneficiary_ != address(0));
        LM = lm_;
        beneficiary = beneficiary_;
        _lockedAmounts = lockedAmounts_;
        _releaseTimes = releaseTimes_;
        revocable = revocable_;
    }

    /**
     * @dev Returns the amount of a locked item.
     */
    function lockedAmount(uint256 index) public view returns (uint256) {
        return _lockedAmounts[index];
    }

    /**
     * @dev Returns the amount of a locked item.
     */
    function releaseTime(uint256 index) public view returns (uint256) {
        return _releaseTimes[index];
    }

    /**
     * @dev Returns the size of locked items.
     */
    function numberOfLockedItems() public view returns (uint256) {
        return _lockedAmounts.length;
    }

    /**
     * @dev Transfers tokens held by the timelock to the beneficiary.
     *      Will only succeed if invoked after the release time.
     */
    function release() external {
        uint256 amount = 0;
        uint256 dday = LM.getDDay();

        while (
            numberOfLockedItems() > 0 &&
            dday + releaseTime(numberOfLockedItems() - 1) < block.timestamp
        ) {
            amount += lockedAmount(numberOfLockedItems() - 1);
            _lockedAmounts.pop();
            _releaseTimes.pop();
        }

        require(
            amount <= LM.balanceOf(address(this)),
            "LeisureMetaTimelock: no tokens to release"
        );

        emit Release(beneficiary, amount, block.timestamp);
        LM.safeTransfer(beneficiary, amount);
    }

    function revoke() external {
        require(revocable, "not revocable");
        require(LM.owner() == _msgSender(), "only owner can revoke");
        while (_lockedAmounts.length > 0) {
            _lockedAmounts.pop();
            _releaseTimes.pop();
        }
        uint256 amount = LM.balanceOf(address(this));
        emit Revoke(beneficiary, amount, block.timestamp);
        LM.safeTransfer(_msgSender(), LM.balanceOf(address(this)));
    }
}
