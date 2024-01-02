// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.21;

import "./ERC20.sol";
import "./VestingWalletUpgradeable.sol";

import "./Lottery.sol";
import "./VestingFactory.sol";

contract Vesting is VestingWalletUpgradeable {
    address internal constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    address public immutable factory = msg.sender;
    address public immutable lucky8Token;
    address public immutable lottery;

    bytes32 public userReferralCode;

    constructor(address _lucky8Token, address _lottery) {
        lucky8Token = _lucky8Token;
        lottery = _lottery;
    }

    /// @dev Method used to initialize.
    function initialize(
        address beneficiary,
        uint64 startTimestamp,
        uint64 durationSeconds,
        bytes32 referralCode
    )
        public
        initializer
    {
        __VestingWallet_init(beneficiary, startTimestamp, durationSeconds);

        userReferralCode = referralCode;
    }

    /// @dev This can be used to lock the Lucky8 tokens in the Lottery contract.
    function lockTokens(uint256 amount) external {
        require(msg.sender == owner(), "Vesting: Only owner can lock tokens");

        ERC20(lucky8Token).approve(lottery, amount);
        Lottery(lottery).lockTokens(amount, userReferralCode);
    }

    /// @dev This can be used to unlock the Lucky8 tokens in the Lottery contract.
    function unlockTokens(uint256 amount) external {
        require(msg.sender == owner(), "Vesting: Only owner can unlock tokens");
        Lottery(lottery).unlockTokens(amount);
    }

    /// @dev This can be used to mint tickets from the Lottery contract.
    function mintTickets() external {
        require(msg.sender == owner(), "Vesting: Only owner can mint tickets");
        Lottery(lottery).mintTickets();
    }

    /// @dev This can be used to claim the prize.
    function claimPrize() external {
        require(msg.sender == owner(), "Vesting: Only owner can claim prize");
        uint256 prize = Lottery(lottery).claimPrize();
        ERC20(USDC_ADDRESS).transfer(owner(), prize);
    }

    /// @dev Override `release(address)` to make it accept only LUCKY8 tokens.
    function release(address token) public override {
        if (token == lucky8Token) {
            uint256 amount = releasable(token);
            uint256 balance = ERC20(lucky8Token).balanceOf(address(this));

            // Unlock tokens from Lottery if needed.
            if (amount > balance) {
                Lottery(lottery).unlockTokens(amount - balance);
            }
        }

        super.release(token);
    }

    /// @dev Override `releasable(address)` to make it return the releasable amount for LUCKY8 tokens.
    function releasable(address token) public view override returns (uint256) {
        if (token == lucky8Token) {
            return vestedAmount(token, uint64(block.timestamp)) - released(token);
        }

        return super.releasable(token);
    }

    /// @dev Override `vestedAmount(address, uint64)` to make it return the balance and the amount locked.
    function vestedAmount(address token, uint64 timestamp) public view override returns (uint256) {
        if (token == lucky8Token) {
            return _vestingSchedule(_totalTokens() + released(token), timestamp);
        }

        return super.vestedAmount(token, timestamp);
    }

    /// @dev Method to get the $888 token balance.
    function _totalTokens() internal view returns (uint256) {
        uint256 balance = ERC20(lucky8Token).balanceOf(address(this));
        (uint256 locked,,,) = Lottery(lottery).getUserInfo(address(this));
        return balance + locked;
    }

    /// @dev Override implementation of the vesting formula. This returns the amount vested, as a function of time, for
    /// an asset given its total historical allocation.
    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp) internal view override returns (uint256) {
        if (timestamp < start()) return 0;

        uint256 cliffAmount = totalAllocation / 3;
        uint256 releaseMonth = (totalAllocation - cliffAmount) / 3;

        if (timestamp > start() && timestamp < start() + 30 days) {
            return cliffAmount;
        } else if (timestamp >= start() + 30 days && timestamp < start() + 60 days) {
            return cliffAmount + releaseMonth;
        } else if (timestamp >= start() + 60 days && timestamp < start() + 90 days) {
            return cliffAmount + (2 * releaseMonth);
        } else if (timestamp >= start() + 90 days) {
            return totalAllocation;
        }

        return 0;
    }

    /// @dev Override `_transferOwnership` method.
    function _transferOwnership(address newOwner) internal virtual override {
        address oldOwner = owner();
        super._transferOwnership(newOwner);

        VestingFactory(factory).ownershipUpdate(oldOwner, newOwner);
    }
}
