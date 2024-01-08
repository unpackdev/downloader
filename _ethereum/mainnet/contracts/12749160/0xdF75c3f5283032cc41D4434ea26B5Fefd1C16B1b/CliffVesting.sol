//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";


contract CliffVesting is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public immutable cliff;
    uint256 public immutable start;
    uint256 public immutable duration;
    uint256 public released;

    // Beneficiary of token after they are released
    address public immutable beneficiary;
    IERC20 public immutable token;

    event TokensReleased(uint256 amount);

    // ------------------------
    // CONSTRUCTOR
    // ------------------------

    /// @dev Creates a vesting contract that vests its balance of any ERC20 token to the
    /// beneficiary, gradually in a linear fashion until start + duration. By then all
    /// of the balance will have vested.
    /// @param beneficiary_ address of the beneficiary to whom vested token are transferred
    /// @param cliffDuration_ duration in seconds of the cliff in which token will begin to vest
    /// @param duration_ duration in seconds of the period in which the token will vest
    /// @param token_ address of the locked token
    constructor(
        address beneficiary_,
        uint256 cliffDuration_,
        uint256 duration_,
        address token_
    ) {
        require(beneficiary_ != address(0));
        require(token_ != address(0));
        require(cliffDuration_ <= duration_);
        require(duration_ > 0);

        beneficiary = beneficiary_;
        token = IERC20(token_);
        duration = duration_;
        start = block.timestamp;
        cliff = block.timestamp.add(cliffDuration_);
    }

    // ------------------------
    // SETTERS
    // ------------------------

    /// @notice Transfers vested tokens to beneficiary
    function release() external {
        uint256 unreleased = _releasableAmount();

        require(unreleased > 0);

        released = released.add(unreleased);

        token.safeTransfer(beneficiary, unreleased);

        emit TokensReleased(unreleased);
    }

    // ------------------------
    // INTERNAL
    // ------------------------

    /// @notice Calculates the amount that has already vested but hasn't been released yet
    function _releasableAmount() private view returns (uint256) {
        return _vestedAmount().sub(released);
    }

    /// @notice Calculates the amount that has already vested
    function _vestedAmount() private view returns (uint256) {
        uint256 currentBalance = token.balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(released);

        if (block.timestamp < cliff) {
            return 0;
        } else if (block.timestamp >= start.add(duration)) {
            return totalBalance;
        } else {
            return totalBalance.mul(block.timestamp.sub(start)).div(duration);
        }
    }
}