// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.3;

import "./ERC20.sol";

/**
    @notice Great scott! Einstein is the first dog to travel to the future!
    Apparently some MPH sent EIN into the future, and millions of them came
    back! It makes no sense!
    @dev Convert your MPH into EIN and vice versa. But there's a catch: burning
    EIN to MPH is instant, while minting EIN using MPH has a linear unlock schedule.
 */
contract Einstein is ERC20("Einstein", "EIN") {
    uint256 internal constant _PRECISION = 10**18;

    ERC20 public immutable mph;
    uint256 public immutable multiplier; // 1 MPH = `multiplier` EIN
    uint256 public immutable unlockTime; // seconds for minted EIN to be unlocked

    struct UnlockInfo {
        uint256 startTime;
        uint256 endTime;
        uint256 amount;
    }
    mapping(address => UnlockInfo) public accountUnlockInfo;

    constructor(
        address _mph,
        uint256 _multiplier,
        uint256 _unlockTime
    ) {
        require(
            _mph != address(0) && _multiplier > 0 && _unlockTime > 0,
            "Invalid input"
        );
        mph = ERC20(_mph);
        multiplier = _multiplier;
        unlockTime = _unlockTime;
    }

    function woof(uint256 mphAmount) external {
        // transfer MPH from account
        mph.transferFrom(msg.sender, address(this), mphAmount);

        // mint locked EIN to account
        UnlockInfo memory unlockInfo = accountUnlockInfo[msg.sender];
        uint256 einAmount = mphToEIN(mphAmount);
        if (block.timestamp >= unlockInfo.endTime) {
            // fully unlocked
            // mint unlocked amount
            if (unlockInfo.amount > 0) {
                _mint(msg.sender, unlockInfo.amount);
            }
            // create new locked EIN
            accountUnlockInfo[msg.sender] = UnlockInfo({
                startTime: block.timestamp,
                endTime: block.timestamp + unlockTime,
                amount: einAmount
            });
        } else {
            // partly unlocked
            // mint unlocked amount
            uint256 unlockedAmount =
                (unlockInfo.amount * (block.timestamp - unlockInfo.startTime)) /
                    (unlockInfo.endTime - unlockInfo.startTime);
            if (unlockedAmount > 0) {
                _mint(msg.sender, unlockedAmount);
            }
            // create new locked EIN
            // consisting of new amount + previous locked amount
            accountUnlockInfo[msg.sender] = UnlockInfo({
                startTime: block.timestamp,
                endTime: block.timestamp + unlockTime,
                amount: einAmount + unlockInfo.amount - unlockedAmount
            });
        }
    }

    function unwoof(uint256 einAmount) external {
        // Note: _updateAccount() is auto-triggered by _beforeTokenTransfer()
        // so no need to unlock tokens first
        // burn EIN from account
        _burn(msg.sender, einAmount);

        // transfer MPH to account
        mph.transfer(msg.sender, einToMPH(einAmount));
    }

    function balanceOf(address account)
        public
        view
        override
        returns (uint256 balance)
    {
        balance = super.balanceOf(account);
        UnlockInfo memory unlockInfo = accountUnlockInfo[account];
        if (block.timestamp >= unlockInfo.endTime) {
            // fully unlocked
            balance += unlockInfo.amount;
        } else {
            // partly unlocked
            balance +=
                (unlockInfo.amount * (block.timestamp - unlockInfo.startTime)) /
                (unlockInfo.endTime - unlockInfo.startTime);
        }
    }

    function einToMPH(uint256 einAmount) public view returns (uint256) {
        return einAmount / multiplier;
    }

    function mphToEIN(uint256 mphAmount) public view returns (uint256) {
        return mphAmount * multiplier;
    }

    function _beforeTokenTransfer(
        address from,
        address, /*to*/
        uint256 /*amount*/
    ) internal override {
        if (from != address(0)) {
            _updateAccount(from);
        }
    }

    function _updateAccount(address account) internal {
        UnlockInfo memory unlockInfo = accountUnlockInfo[account];
        if (block.timestamp >= unlockInfo.endTime) {
            // fully unlocked
            // mint unlocked amount
            if (unlockInfo.amount > 0) {
                _mint(account, unlockInfo.amount);
            }
            delete accountUnlockInfo[account];
        } else {
            // partly unlocked
            // mint unlocked amount
            uint256 unlockedAmount =
                (unlockInfo.amount * (block.timestamp - unlockInfo.startTime)) /
                    (unlockInfo.endTime - unlockInfo.startTime);
            if (unlockedAmount > 0) {
                _mint(account, unlockedAmount);
            }
            // update unlock info
            accountUnlockInfo[account].startTime = block.timestamp;
            accountUnlockInfo[account].amount =
                unlockInfo.amount -
                unlockedAmount;
        }
    }
}
