// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./ITimelockedDelegator.sol";
import "./LinearTokenTimelock.sol";

/// @title a proxy delegate contract for RING
/// @author Ring Protocol
contract Delegatee is Ownable {
    IRing public ring;

    /// @notice Delegatee constructor
    /// @param _delegatee the address to delegate RING to
    /// @param _ring the RING token address
    constructor(address _delegatee, address _ring) {
        ring = IRing(_ring);
        ring.delegate(_delegatee);
    }

    /// @notice send RING back to timelock and selfdestruct
    function withdraw() public onlyOwner {
        IRing _ring = ring;
        uint256 balance = _ring.balanceOf(address(this));
        _ring.transfer(owner(), balance);
        selfdestruct(payable(owner()));
    }
}

/// @title a timelock for RING allowing for sub-delegation
/// @author Ring Protocol
/// @notice allows the timelocked RING to be delegated by the beneficiary while locked
contract TimelockedDelegator is ITimelockedDelegator, LinearTokenTimelock {
    using SafeMathCopy for uint256;

    /// @notice associated delegate proxy contract for a delegatee
    mapping(address => address) public override delegateContract;

    /// @notice associated delegated amount of RING for a delegatee
    /// @dev Using as source of truth to prevent accounting errors by transferring to Delegate contracts
    mapping(address => uint256) public override delegateAmount;

    /// @notice the RING token contract
    IRing public override ring;

    /// @notice the total delegated amount of RING
    uint256 public override totalDelegated;

    /// @notice Delegatee constructor
    /// @param _ring the RING token address
    /// @param _beneficiary default delegate, admin, and timelock beneficiary
    /// @param _duration duration of the token timelock window
    constructor(
        address _ring,
        address _beneficiary,
        uint256 _duration
    ) LinearTokenTimelock(_beneficiary, _duration, _ring) {
        ring = IRing(_ring);
        ring.delegate(_beneficiary);
    }

    /// @notice delegate locked RING to a delegatee
    /// @param delegatee the target address to delegate to
    /// @param amount the amount of RING to delegate. Will increment existing delegated RING
    function delegate(address delegatee, uint256 amount)
        public
        override
        onlyBeneficiary
    {
        require(
            amount <= _ringBalance(),
            "TimelockedDelegator: Not enough Ring"
        );

        // withdraw and include an existing delegation
        if (delegateContract[delegatee] != address(0)) {
            amount = amount.add(undelegate(delegatee));
        }

        IRing _ring = ring;
        address _delegateContract =
            address(new Delegatee(delegatee, address(_ring)));
        delegateContract[delegatee] = _delegateContract;

        delegateAmount[delegatee] = amount;
        totalDelegated = totalDelegated.add(amount);

        _ring.transfer(_delegateContract, amount);

        emit Delegate(delegatee, amount);
    }

    /// @notice return delegated RING to the timelock
    /// @param delegatee the target address to undelegate from
    /// @return the amount of RING returned
    function undelegate(address delegatee)
        public
        override
        onlyBeneficiary
        returns (uint256)
    {
        address _delegateContract = delegateContract[delegatee];
        require(
            _delegateContract != address(0),
            "TimelockedDelegator: Delegate contract nonexistent"
        );

        Delegatee(_delegateContract).withdraw();

        uint256 amount = delegateAmount[delegatee];
        totalDelegated = totalDelegated.sub(amount);

        delegateContract[delegatee] = address(0);
        delegateAmount[delegatee] = 0;

        emit Undelegate(delegatee, amount);

        return amount;
    }

    /// @notice calculate total RING held plus delegated
    /// @dev used by LinearTokenTimelock to determine the released amount
    function totalToken() public view override returns (uint256) {
        return _ringBalance().add(totalDelegated);
    }

    /// @notice accept beneficiary role over timelocked RING. Delegates all held (non-subdelegated) ring to beneficiary
    function acceptBeneficiary() public override {
        _setBeneficiary(msg.sender);
        ring.delegate(msg.sender);
    }

    function _ringBalance() internal view returns (uint256) {
        return ring.balanceOf(address(this));
    }
}
